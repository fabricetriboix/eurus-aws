import os
from enum import Enum
from typing import Literal
from pydantic import BaseModel, Field, model_validator
from typing_extensions import Self
from aws_lambda_powertools import Logger
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtensionOID
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization, hashes
import boto3
import json
from datetime import datetime, timezone, timedelta


logger = Logger(service="pki")
region = os.environ['AWS_REGION']


class BasicConstraints(BaseModel):
    is_critical: bool = Field(
        default=False,
        description="Whether the Basic Constraints extension is critical")
    is_ca: bool = Field(
        default=False,
        description="Whether the certificate is a CA certificate")
    path_length: int = Field(
        default=0,
        description="Maximum length of the chain",
        ge=1)


class SubjectAlternativeNames(BaseModel):
    is_critical: bool = Field(
        default=False,
        description="Whether the Subject Alternative Names extension is critical")
    dns_names: list[str] = Field(
        default=[],
        description="The DNS names to add to the Subject Alternative Names extension")


class KeyUsageEnum(Enum):
    DIGITAL_SIGNATURE  = "DigitalSignature"   # Can verify digital signatures
    CONTENT_COMMITMENT = "ContentCommitment"  # AKA non-repudiation
    KEY_ENCIPHERMENT   = "KeyEncipherment"    # Can encrypt keys
    DATA_ENCIPHERMENT  = "DataEncipherment"   # Can encrypt data
    KEY_AGREEMENT      = "KeyAgreement"       # Key agreement, eg: Diffie-Hellman
    KEY_CERT_SIGN      = "KeyCertSign"        # Can sign certificates; if set, `BasicConstraints.is_ca` must be `True`
    ENCIPHER_ONLY      = "EncipherOnly"       # Can encrypt following a key agreement
    DECIPHER_ONLY      = "DecipherOnly"       # Can decrypt following a key agreement


class KeyUsage(BaseModel):
    is_critical: bool = Field(
        default=False,
        description="Whether the Key Usage extension is critical")
    usages: list[KeyUsageEnum] = Field(
        default=[],
        description="The usages to add to the Key Usage extension")


class CertificateParameters(BaseModel):
    # Generalities
    key_size: Literal[2048, 3072, 4096] = Field(default=2048, description="The number of bits to use for the key")
    validity_days: int = Field(..., description="The number of days the certificate is valid for", ge=1)

    # Distinguished Name
    country_name: str | None = Field(default=None, description="The country name to use for the certificate", min_length=2, max_length=2)
    state_or_province_name: str | None = Field(default=None, description="The state or province name to use for the certificate")
    locality_name: str | None = Field(default=None, description="The locality name to use for the certificate")
    organization_name: str | None = Field(default=None, description="The organization name to use for the certificate")
    organizational_unit_name: str | None = Field(default=None, description="The organizational unit name to use for the certificate")
    email_address: str | None = Field(default=None, description="The email address to use for the certificate")
    common_name: str = Field(..., description="The common name to use for the certificate (must be the DNS name the certficate will be used for)")

    # Basic Constraints
    basic_constraints: BasicConstraints | None = Field(default=None, description="The Basic Constraints extension")

    # Subject Alternative Names
    sans: SubjectAlternativeNames | None = Field(default=None, description="The Subject Alternative Names extension")

    # Key Usage
    key_usage: KeyUsage | None = Field(default=None, description="The Key Usage extension")

    # Certificate signing - if `None`, the certificate will be self-signed
    ca_key_ssm_param_name: str | None = Field(default=None, description="The SSM parameter name of the CA key to use for the certificate signing")
    ca_cert_ssm_param_name: str | None = Field(default=None, description="The SSM parameter name of the CA certificate to use for the certificate signing")

    # Where to store
    key_ssm_param_name: str = Field(..., description="The SSM parameter name to store the private key in")
    key_tags: dict[str, str] = Field(default={}, description="The tags to add to the private key SSM parameter")
    cert_ssm_param_name: str = Field(..., description="The SSM parameter name to store the certificate in")
    cert_tags: dict[str, str] = Field(default={}, description="The tags to add to the certificate SSM parameter")

    @model_validator(mode="after")
    def validate_critical(self) -> Self:
        is_ba_critical = self.basic_constraints is not None and self.basic_constraints.is_critical
        is_sans_critical = self.sans is not None and self.sans.is_critical
        if not is_ba_critical and not is_sans_critical:
            raise ValueError("Either the Basic Constraints or the Subject Alternative Names extension must be critical")
        return self

    @model_validator(mode="after")
    def validate_key_usage(self) -> Self:
        is_key_usage_cert_sign = self.key_usage is not None and KeyUsageEnum.KEY_CERT_SIGN in self.key_usage.usages
        is_ca = self.basic_constraints is not None and self.basic_constraints.is_ca
        if is_key_usage_cert_sign and not is_ca:
            raise ValueError("If the `KeyCertSign` key usage is set, the `basic_constraints.is_ca` must be `True`")
        return self

    @model_validator(mode="after")
    def validate_ca(self) -> Self:
        if self.ca_key_ssm_param_name is not None and self.ca_cert_ssm_param_name is None:
            raise ValueError("If the CA key SSM parameter name is set, the CA certificate SSM parameter name must also be set")
        if self.ca_key_ssm_param_name is None and self.ca_cert_ssm_param_name is not None:
            raise ValueError("If the CA certificate SSM parameter name is set, the CA key SSM parameter name must also be set")
        return self


class Key(BaseModel):
    cert_arn: str
    cert_ssm_param: str
    key: str = Field(..., description="The private key in PEM format")


def _get_key_from_ssm(
    ssm_client: boto3.client,
    param_name: str
) -> Key:
    """
    Get the key from the SSM parameter.
    """
    tmp = ssm_client.get_parameter(Name=param_name, WithDecryption=True)
    return Key.model_validate_json(tmp['Parameter']['Value'])


class Certificate(BaseModel):
    cert_arn: str
    key_ssm_param: str

    # CA cert and key SSM parameters will be `None` for self-signed certificates
    ca_cert_ssm_param: str | None = None
    ca_key_ssm_param: str | None = None


def _get_certificate_from_ssm(
    ssm_client: boto3.client,
    param_name: str
) -> Certificate:
    """
    Get the certificate from the SSM parameter.
    """
    tmp = ssm_client.get_parameter(Name=param_name, WithDecryption=True)
    return Certificate.model_validate_json(tmp['Parameter']['Value'])


def _add_attribute_if_present(
    params: CertificateParameters,
    attribute_name: str,
    attributes: list[x509.Extension],
    oid: NameOID
) -> None:
    if getattr(params, attribute_name) is None:
        logger.debug(f"Attribute `{attribute_name}` is not present, skipping")
    else:
        value = getattr(params, attribute_name)#.encode('utf-8')
        logger.debug(f"Adding attribute `{attribute_name}` with value `{value}` to subject")
        attributes.append(x509.NameAttribute(oid, str(value)))


def _upsert_ssm_param(
    ssm_client: boto3.client,
    ksm_key_id: str,
    name: str,
    value: str,
    desc: str,
    tags: dict[str, str]
) -> None:
    """
    Save the SSM parameter.
    
    Return value: The ARN of the parameter
    """
    ssm_client.put_parameter(
        Name=name,
        Value=value,
        Description=desc,
        Type="SecureString",
        KeyId=ksm_key_id,
        Overwrite=True
    )

    # Erase all existing tags
    logger.debug(f"upsert_ssm_param: Calling ssm_client.list_tags_for_resource(ResourceId={name})")
    resp = ssm_client.list_tags_for_resource(
        ResourceType="Parameter",
        ResourceId=name
    )
    existing_tag_keys = [tag['Key'] for tag in resp['TagList']]
    if existing_tag_keys:
        logger.debug(f"upsert_ssm_param: Calling ssm_client.remove_tags_from_resource(ResourceId={name})")
        ssm_client.remove_tags_from_resource(
            ResourceType="Parameter",
            ResourceId=name,
            TagKeys=existing_tag_keys
        )

    # Save the new tags
    if tags:
        logger.debug(f"upsert_ssm_param: Calling ssm_client.add_tags_to_resource(ResourceId={name})")
        ssm_client.add_tags_to_resource(
            ResourceType="Parameter",
            ResourceId=name,
            Tags=[{'Key': key, 'Value': value} for key, value in tags.items()]
        )

    # Return the ARN of the parameter
    resp = ssm_client.get_parameter(Name=name)
    arn = resp['Parameter']['ARN']
    logger.debug(f"upsert_ssm_param: Success - ARN: {arn}")


def _chain_certificate(
    ssm_client: boto3.client,
    acm_client: boto3.client,
    chain: str,
    ca_cert: Certificate
) -> str:
    """
    Chain the certificate `cert` into the chain `chain`.
    
    Return value: The certificate chain with `cert` added
    """
    tmp = acm_client.get_certificate(
        CertificateArn=ca_cert.cert_arn
    )
    chain += tmp['Certificate']
    if ca_cert.ca_cert_ssm_param is None:
        return chain  # Self-signed certificate => end of chain

    parent_ca_cert = _get_certificate_from_ssm(ssm_client, ca_cert.ca_cert_ssm_param)
    return _chain_certificate(ssm_client, acm_client, chain, parent_ca_cert)


def create_or_renew_certificate(
    params: CertificateParameters,
    ksm_key_id: str
) -> Certificate:
    # Build subject name

    attributes = []
    _add_attribute_if_present(params, 'country_name', attributes, NameOID.COUNTRY_NAME)
    _add_attribute_if_present(params, 'state_or_province_name', attributes, NameOID.STATE_OR_PROVINCE_NAME)
    _add_attribute_if_present(params, 'locality_name', attributes, NameOID.LOCALITY_NAME)
    _add_attribute_if_present(params, 'organization_name', attributes, NameOID.ORGANIZATION_NAME)
    _add_attribute_if_present(params, 'organizational_unit_name', attributes, NameOID.ORGANIZATIONAL_UNIT_NAME)
    _add_attribute_if_present(params, 'email_address', attributes, NameOID.EMAIL_ADDRESS)
    _add_attribute_if_present(params, 'common_name', attributes, NameOID.COMMON_NAME)

    subject = x509.Name(attributes)

    # Add extensions, if any

    extensions = []

    if params.basic_constraints:
        logger.debug(f"Adding Basic Constraints extension with value `{params.basic_constraints}`")
        is_ca = params.basic_constraints.is_ca
        extension = x509.Extension(
            oid=ExtensionOID.BASIC_CONSTRAINTS,
            critical=params.basic_constraints.is_critical,
            value=x509.BasicConstraints(
                ca=is_ca,
                path_length=params.basic_constraints.path_length if is_ca else None
            )
        )
        extensions.append(extension)
    else:
        is_ca = False

    if params.sans:
        logger.debug(f"Adding Subject Alternative Names extension with value `{params.sans}`")
        extension = x509.Extension(
            oid=ExtensionOID.SUBJECT_ALTERNATIVE_NAME,
            critical=params.sans.is_critical,
            value=x509.SubjectAlternativeName([
                x509.DNSName(name) for name in params.sans.dns_names
            ])
        )
        extensions.append(extension)

    if params.key_usage:
        logger.debug(f"Adding Key Usage extension with value `{params.key_usage}`")
        extension = x509.Extension(
            oid=ExtensionOID.KEY_USAGE,
            critical=params.key_usage.is_critical,
            value=x509.KeyUsage(
                digital_signature=KeyUsageEnum.DIGITAL_SIGNATURE in params.key_usage.usages,
                content_commitment=KeyUsageEnum.CONTENT_COMMITMENT in params.key_usage.usages,
                key_encipherment=KeyUsageEnum.KEY_ENCIPHERMENT in params.key_usage.usages,
                data_encipherment=KeyUsageEnum.DATA_ENCIPHERMENT in params.key_usage.usages,
                key_agreement=KeyUsageEnum.KEY_AGREEMENT in params.key_usage.usages,
                key_cert_sign=KeyUsageEnum.KEY_CERT_SIGN in params.key_usage.usages,
                crl_sign=False,
                encipher_only=KeyUsageEnum.ENCIPHER_ONLY in params.key_usage.usages,
                decipher_only=KeyUsageEnum.DECIPHER_ONLY in params.key_usage.usages
            )
        )
        extensions.append(extension)

    # Get the CA key and certificate if required

    acm_client = boto3.client('acm', region_name=region)
    ssm_client = boto3.client('ssm', region_name=region)

    if params.ca_key_ssm_param_name is None or params.ca_cert_ssm_param_name is None:
        logger.debug("No CA key or certificate provided, certificate will be self-signed")
        ca_key = None
        ca_cert = None
        ca_key_obj = None
        ca_cert_obj = None
        issuer = subject
    else:
        logger.debug(f"Getting CA key and certificate from SSM parameters `{params.ca_key_ssm_param_name}` and `{params.ca_cert_ssm_param_name}`")
        ca_key = _get_key_from_ssm(ssm_client, params.ca_key_ssm_param_name)
        ca_key_obj = serialization.load_pem_private_key(
            ca_key.key.encode('utf-8'),
            password=None,
            backend=default_backend()
        )

        ca_cert = _get_certificate_from_ssm(ssm_client, params.ca_cert_ssm_param_name)
        acm_cert = acm_client.get_certificate(
            CertificateArn=ca_cert.cert_arn
        )
        ca_cert_obj = x509.load_pem_x509_certificate(
            acm_cert['Certificate'].encode('utf-8'),
            backend=default_backend()
        )
        issuer = ca_cert_obj.subject

    # Generate the private key

    logger.debug(f"Generating RSA private key with size {params.key_size} bits")
    key_obj = rsa.generate_private_key(
        public_exponent=65537,
        key_size=params.key_size,
        backend=default_backend()
    )
    key_pem = key_obj.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    ).decode('utf-8')

    # Generate the certificate

    logger.debug(f"Generating certificate `{params.cert_ssm_param_name}` with subject `{subject}`")
    cert_obj = x509.CertificateBuilder().subject_name(
        subject
    ).issuer_name(
        issuer
    ).public_key(
        key_obj.public_key()
    ).serial_number(
        x509.random_serial_number()
    ).not_valid_before(
        datetime.now(timezone.utc)
    ).not_valid_after(
        datetime.now(timezone.utc) + timedelta(days=params.validity_days)
    )

    for extension in extensions:
        cert_obj = cert_obj.add_extension(extension.value, extension.critical)

    if ca_key is not None:
        logger.debug(f"Signing certificate `{params.cert_ssm_param_name}` with CA key `{params.ca_key_ssm_param_name}`")
        cert_obj = cert_obj.sign(ca_key_obj, hashes.SHA256(), default_backend())
    else:
        logger.debug(f"Self-signing certificate `{params.cert_ssm_param_name}`")
        cert_obj = cert_obj.sign(key_obj, hashes.SHA256(), default_backend())

    # Save the certificate in ACM

    if ca_cert is not None:
        chain_pem = _chain_certificate(ssm_client, acm_client, "", ca_cert)
    else:
        chain_pem = ""

    cert_arn = None
    try:
        cert = _get_certificate_from_ssm(ssm_client, params.cert_ssm_param_name)
        cert_arn = cert.cert_arn
        acm_client.get_certificate(
            CertificateArn=cert_arn
        )
    except (
        ssm_client.exceptions.ParameterNotFound,
        acm_client.exceptions.ResourceNotFoundException,
    ):
        cert_arn = None

    import_kwargs = {
        "Certificate": cert_obj.public_bytes(serialization.Encoding.PEM),
        "PrivateKey": key_pem.encode('utf-8'),
    }
    if chain_pem:
        import_kwargs["CertificateChain"] = chain_pem

    if cert_arn is None:
        logger.info(f"Creating certificate `{params.cert_ssm_param_name}`")
        resp = acm_client.import_certificate(**import_kwargs)
        cert_arn = resp['CertificateArn']
    else:
        logger.info(f"Updating certificate `{params.cert_ssm_param_name}` - ARN: {cert_arn}")
        acm_client.import_certificate(
            CertificateArn=cert_arn,
            **import_kwargs
        )

    # Save the private key

    logger.debug(f"Saving private key `{params.key_ssm_param_name}`")

    data = {
        'cert_arn': cert_arn,
        'cert_ssm_param': params.cert_ssm_param_name,
        'key': key_pem
    }

    try:
        _upsert_ssm_param(
            ssm_client,
            ksm_key_id,
            params.key_ssm_param_name,
            json.dumps(data),
            f"Private key for certificate {params.cert_ssm_param_name}",
            params.key_tags
        )
    except Exception as e:
        logger.error(f"Error saving private key `{params.key_ssm_param_name}`: {e}")
        acm_client.delete_certificate(CertificateArn=cert_arn)
        raise e

    # Save the certificate

    logger.debug(f"Saving certificate `{params.cert_ssm_param_name}`")

    data = {
        'cert_arn': cert_arn,
        'key_ssm_param': params.key_ssm_param_name,
        'ca_cert_ssm_param': params.ca_cert_ssm_param_name,
        'ca_key_ssm_param': params.ca_key_ssm_param_name
    }

    try:
        _upsert_ssm_param(
            ssm_client,
            ksm_key_id,
            params.cert_ssm_param_name,
            json.dumps(data),
            f"X.509 certificate for {params.cert_ssm_param_name}",
            params.cert_tags
        )
    except Exception as e:
        logger.error(f"Error saving certificate `{params.cert_ssm_param_name}`: {e}")
        ssm_client.delete_parameter(Name=params.key_ssm_param_name)
        acm_client.delete_certificate(CertificateArn=cert_arn)
        raise e

    return Certificate(
        cert_arn=cert_arn,
        key_ssm_param=params.key_ssm_param_name,
        ca_cert_ssm_param=params.ca_cert_ssm_param_name,
        ca_key_ssm_param=params.ca_key_ssm_param_name
    )
