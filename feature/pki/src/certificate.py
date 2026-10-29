import os
from enum import Enum
from typing import Literal
from pydantic import BaseModel, Field, model_validator
from typing_extensions import Self
from aws_lambda_powertools import Logger
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtensionOID
from cryptography.hazmat.primitives.asymmetric import rsa, ec
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization, hashes
import boto3
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
    path_length: int | None = Field(
        default=None,
        description="Maximum length of the chain",
        ge=0)


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
    name: str = Field(..., description="The name of the certificate (used for storage, must be unique in this PKI)")
    key_type: Literal["RSA", "ECDSA"] = Field(default="RSA", description="The type of key to use for the certificate")
    key_size: Literal[2048, 3072, 4096, 256, 384, 521] = Field(default=2048, description="The number of bits to use for the key; valid values for RSA: 2048, 3072, 4096; valid values for ECDSA: 256, 384, 521")
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
    ca_name: str | None = Field(default=None, description="The name of the CA certificate to use for the certificate signing")

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


class Key(BaseModel):
    name: str
    cert_arn: str
    key_pem: str = Field(..., description="The private key in PEM format")


def _get_key_from_s3(
    s3_client: boto3.client,
    name: str
) -> Key:
    """
    Get the key from the S3 bucket.
    """
    bucket_name = os.environ['PKI_BUCKET_NAME']
    path = f"pki/keys/{name}.key.json"
    response = s3_client.get_object(Bucket=bucket_name, Key=path)
    return Key.model_validate_json(response['Body'].read().decode('utf-8'))


class Certificate(BaseModel):
    name: str
    cert_arn: str

    # CA name will be `None` for self-signed certificates
    ca_name: str | None = None


def _get_certificate_from_s3(
    s3_client: boto3.client,
    name: str
) -> Certificate:
    """
    Get the certificate from the S3 bucket.
    """
    bucket_name = os.environ['PKI_BUCKET_NAME']
    path = f"pki/certs/{name}.crt.json"
    response = s3_client.get_object(Bucket=bucket_name, Key=path)
    return Certificate.model_validate_json(response['Body'].read().decode('utf-8'))


def _add_attribute_if_present(
    params: CertificateParameters,
    attribute_name: str,
    attributes: list[x509.Extension],
    oid: NameOID
) -> None:
    if getattr(params, attribute_name) is None:
        logger.debug(f"Attribute `{attribute_name}` is not present, skipping")
    else:
        value = getattr(params, attribute_name)
        logger.debug(f"Adding attribute `{attribute_name}` with value `{value}` to subject")
        attributes.append(x509.NameAttribute(oid, str(value)))


def _save_to_s3(
    s3_client: boto3.client,
    path: str,
    data: str
) -> str:
    """
    Save the data to the S3 bucket.

    Returns the version ID of the object.
    """
    bucket_name = os.environ['PKI_BUCKET_NAME']
    response = s3_client.put_object(
        Bucket=bucket_name,
        Key=path,
        Body=data.encode('utf-8')
    )
    return response['VersionId']


def _s3_delete_version(
    s3_client: boto3.client,
    path: str,
    version_id: str
) -> None:
    """
    Delete the given version of the `path` object in the S3 bucket.
    """
    bucket_name = os.environ['PKI_BUCKET_NAME']
    s3_client.delete_object(
        Bucket=bucket_name,
        Key=path,
        VersionId=version_id
    )


def _chain_certificate(
    s3_client: boto3.client,
    acm_client: boto3.client,
    chain: str,
    ca_cert: Certificate
) -> str:
    """
    Chain the certificate `ca_cert` into the chain `chain`.
    
    Return value: The certificate chain with `ca_cert` added
    """
    response = acm_client.get_certificate(
        CertificateArn=ca_cert.cert_arn
    )
    chain += response['Certificate']
    if ca_cert.ca_name is None:
        return chain  # Self-signed certificate => end of the chain

    parent_ca_cert = _get_certificate_from_s3(s3_client, ca_cert.ca_name)
    return _chain_certificate(s3_client, acm_client, chain, parent_ca_cert)


def _build_subject_name(
    params: CertificateParameters
) -> x509.Name:
    """
    Build the subject name for the certificate.
    """
    attributes = []
    _add_attribute_if_present(params, 'country_name', attributes, NameOID.COUNTRY_NAME)
    _add_attribute_if_present(params, 'state_or_province_name', attributes, NameOID.STATE_OR_PROVINCE_NAME)
    _add_attribute_if_present(params, 'locality_name', attributes, NameOID.LOCALITY_NAME)
    _add_attribute_if_present(params, 'organization_name', attributes, NameOID.ORGANIZATION_NAME)
    _add_attribute_if_present(params, 'organizational_unit_name', attributes, NameOID.ORGANIZATIONAL_UNIT_NAME)
    _add_attribute_if_present(params, 'email_address', attributes, NameOID.EMAIL_ADDRESS)
    _add_attribute_if_present(params, 'common_name', attributes, NameOID.COMMON_NAME)

    return x509.Name(attributes)


def _build_extensions(
    params: CertificateParameters
) -> list[x509.Extension]:
    """
    Build the extensions for the certificate.
    """
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
    
    return extensions


def _generate_private_key(
    params: CertificateParameters
) -> rsa.RSAPrivateKey | ec.EllipticCurvePrivateKey:
    """
    Generate the private key for the certificate.
    """
    logger.debug(f"Generating {params.key_type} private key with size {params.key_size} bits")
    if params.key_type == "RSA":
        if params.key_size not in [2048, 3072, 4096]:
            raise ValueError(f"Invalid key size: {params.key_size}; allowed values are: 2048, 3072, 4096")
        key_obj = rsa.generate_private_key(
            public_exponent=65537,
            key_size=params.key_size,
            backend=default_backend()
        )
    elif params.key_type == "ECDSA":
        if params.key_size == 256:
            curve = ec.SECP256R1()
        elif params.key_size == 384:
            curve = ec.SECP384R1()
        elif params.key_size == 521:
            curve = ec.SECP521R1()
        else:
            raise ValueError(f"Invalid key size: {params.key_size}; allowed values are: 256, 384, 521")
        key_obj = ec.generate_private_key(curve)
    else:
        raise ValueError(f"Invalid key type: {params.key_type}")

    return key_obj


def _get_cert_from_acm(
    s3_client: boto3.client,
    acm_client: boto3.client,
    name: str
) -> tuple[str | None, str | None, str | None]:
    """
    Get the certificate from ACM and return its ARN, the PEM-encoded certificate and the PEM-encoded certificate chain.

    Returns the certificate ARN, the PEM-encoded certificate and the PEM-encoded certificate chain.
    """
    cert_arn = None
    cert_pem = None
    chain_pem = None

    try:
        cert = _get_certificate_from_s3(s3_client, name)
        cert_arn = cert.cert_arn
        response = acm_client.get_certificate(
            CertificateArn=cert_arn
        )
        cert_pem = response['Certificate']
        chain_pem = response.get('CertificateChain', None)
    except (
        s3_client.exceptions.NoSuchKey,
        acm_client.exceptions.ResourceNotFoundException,
    ):
        cert_arn = None
        cert_pem = None
        chain_pem = None
    return cert_arn, cert_pem, chain_pem


def _acm_save_cert(
    acm_client: boto3.client,
    name: str,
    cert_arn: str | None,
    key_pem: str,
    cert_pem: str,
    chain_pem: str | None
) -> str:
    """
    Save the certificate in ACM.

    Returns the certificate ARN.
    """
    import_kwargs = {
        "Certificate": cert_pem.encode('utf-8'),
        "PrivateKey": key_pem.encode('utf-8')
    }
    if chain_pem:
        import_kwargs["CertificateChain"] = chain_pem.encode('utf-8')

    if cert_arn:
        import_kwargs["CertificateArn"] = cert_arn
        logger.info(f"Updating certificate `{name}` - ARN: {cert_arn}")
    else:
        logger.info(f"Creating certificate `{name}`")

    try:
        response = acm_client.import_certificate(**import_kwargs)
        cert_arn = response['CertificateArn']
    except Exception as e:
        logger.error(f"Error saving certificate `{name}` in ACM: {e}")
        raise e
    return cert_arn


def create_or_renew_certificate(
    params: CertificateParameters
) -> Certificate:
    acm_client = boto3.client('acm', region_name=region)
    s3_client = boto3.client('s3', region_name=region)

    subject = _build_subject_name(params)
    extensions = _build_extensions(params)

    # Get the CA key and certificate if required
    if params.ca_name is None:
        logger.debug("No CA key or certificate provided, certificate will be self-signed")
        ca_key = None
        ca_cert = None
        ca_key_obj = None
        ca_cert_obj = None
        issuer = subject
    else:
        logger.debug(f"Getting CA `{params.ca_name}` key and certificate from S3 bucket")
        ca_key = _get_key_from_s3(s3_client, params.ca_name)
        ca_key_obj = serialization.load_pem_private_key(
            ca_key.key_pem.encode('utf-8'),
            password=None,
            backend=default_backend()
        )

        ca_cert = _get_certificate_from_s3(s3_client, params.ca_name)
        response = acm_client.get_certificate(
            CertificateArn=ca_cert.cert_arn
        )
        ca_cert_obj = x509.load_pem_x509_certificate(
            response['Certificate'].encode('utf-8'),
            backend=default_backend()
        )
        issuer = ca_cert_obj.subject

    key_obj = _generate_private_key(params)
    key_pem = key_obj.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    ).decode('utf-8')

    logger.debug(f"Generating certificate `{params.name}` with subject `{subject}`")
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

    if ca_key is None:
        logger.debug(f"Self-signing certificate `{params.name}`")
        cert_obj = cert_obj.sign(key_obj, hashes.SHA256(), default_backend())
    else:
        logger.debug(f"Signing certificate `{params.name}` with CA key `{params.ca_name}`")
        cert_obj = cert_obj.sign(ca_key_obj, hashes.SHA256(), default_backend())

    cert_arn, old_cert_pem, old_chain_pem = _get_cert_from_acm(s3_client, acm_client, params.name)
    acm_cert_already_exists = cert_arn is not None
    old_key_pem = None
    if acm_cert_already_exists:
        key = _get_key_from_s3(s3_client, params.name)
        old_key_pem = key.key_pem

    # Save the certificate in ACM
    if ca_cert is not None:
        chain_pem = _chain_certificate(s3_client, acm_client, "", ca_cert)
    else:
        chain_pem = ""
    cert_arn = _acm_save_cert(
        acm_client,
        params.name,
        cert_arn,
        key_pem,
        cert_obj.public_bytes(serialization.Encoding.PEM).decode('utf-8'),
        chain_pem
    )

    logger.debug(f"Saving private key `{params.name}`")
    key = Key(
        name=params.name,
        cert_arn=cert_arn,
        key_pem=key_pem
    )
    try:
        s3_key_version_id = _save_to_s3(
            s3_client,
            f"pki/keys/{params.name}.key.json",
            key.model_dump_json()
        )
    except Exception as e:
        logger.error(f"Error saving private key `{params.name}`: {e}")
        if acm_cert_already_exists:
            logger.info(f"Restoring certificate `{params.name}` in ACM")
            _acm_save_cert(
                acm_client,
                params.name,
                cert_arn,
                old_key_pem,
                old_cert_pem,
                old_chain_pem
            )
            logger.info(f"Certificate `{params.name}` restored in ACM")
        else:
            logger.info(f"Deleting certificate `{params.name}` in ACM")
            acm_client.delete_certificate(CertificateArn=cert_arn)
            logger.info(f"Certificate `{params.name}` deleted in ACM")
        raise e

    logger.debug(f"Saving certificate `{params.name}`")
    certificate = Certificate(
        name=params.name,
        cert_arn=cert_arn,
        ca_name=params.ca_name
    )
    try:
        _save_to_s3(
            s3_client,
            f"pki/certs/{params.name}.crt.json",
            certificate.model_dump_json()
        )
    except Exception as e:
        logger.error(f"Error saving certificate `{params.name}`: {e}")
        try:
            _s3_delete_version(s3_client, f"pki/keys/{params.name}.key.json", s3_key_version_id)
        except Exception as e2:
            logger.warning(f"Failed to delete version `{s3_key_version_id}` of private key `{params.name}`: {e2} - This must be fixed manually")

        if acm_cert_already_exists:
            logger.info(f"Restoring certificate `{params.name}` in ACM")
            _acm_save_cert(
                acm_client,
                params.name,
                cert_arn,
                old_key_pem,
                old_cert_pem,
                old_chain_pem
            )
            logger.info(f"Certificate `{params.name}` restored in ACM")
        else:
            logger.info(f"Deleting certificate `{params.name}` in ACM")
            acm_client.delete_certificate(CertificateArn=cert_arn)
            logger.info(f"Certificate `{params.name}` deleted in ACM")
        raise e

    return Certificate(
        name=params.name,
        cert_arn=cert_arn,
        ca_name=params.ca_name
    )
