import pytest
import moto
import boto3
import freezegun
from unittest import mock

from datetime import datetime, timezone, timedelta
from pydantic import ValidationError
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.x509.oid import NameOID, ExtensionOID

from certificate import (
    CertificateParameters,
    BasicConstraints,
    SubjectAlternativeNames,
    KeyUsage,
    KeyUsageEnum,
    Key,
    Certificate,
    create_or_renew_certificate,
    _upsert_ssm_param,
)


def test_good_cert_param_should_succeed(good_cert_params: CertificateParameters):
    assert good_cert_params.model_dump() == {
        "key_size": 2048,
        "validity_days": 365,
        "country_name": "US",
        "state_or_province_name": "California",
        "locality_name": "San Francisco",
        "organization_name": "Example Inc.",
        "organizational_unit_name": "IT",
        "email_address": "info@example.com",
        "common_name": "example.com",
        "basic_constraints": {
            "is_critical": True,
            "is_ca": False,
            "path_length": 3,
        },
        "sans": {
            "is_critical": False,
            "dns_names": ["example2.com", "example3.com"],
        },
        "key_usage": {
            "is_critical": True,
            "usages": [
                KeyUsageEnum.DIGITAL_SIGNATURE,
                KeyUsageEnum.KEY_ENCIPHERMENT,
            ],
        },
        "ca_key_ssm_param_name": "ca_key",
        "ca_cert_ssm_param_name": "ca_cert",
        "key_ssm_param_name": "key",
        "key_tags": {"Key": "Value"},
        "cert_ssm_param_name": "cert",
        "cert_tags": {"Key": "Value"},
    }


def test_cert_params_with_invalid_key_size_should_fail():
    with pytest.raises(ValidationError):
        CertificateParameters(
            key_size=1023,
            validity_days=365,
            country_name="US",
            state_or_province_name="California",
            locality_name="San Francisco",
            organization_name="Example Inc.",
            organizational_unit_name="IT",
            email_address="info@example.com",
            common_name="example.com",
            basic_constraints=BasicConstraints(
                is_critical=True,
                is_ca=True,
                path_length=3,
            ),
            sans=SubjectAlternativeNames(
                is_critical=True,
                dns_names=["example2.com", "example3.com"],
            ),
            key_usage=KeyUsage(
                is_critical=True,
                usages=[KeyUsageEnum.DIGITAL_SIGNATURE, KeyUsageEnum.KEY_ENCIPHERMENT, KeyUsageEnum.KEY_CERT_SIGN]
            ),
            ca_key_ssm_param_name="ca_key",
            ca_cert_ssm_param_name="ca_cert",
            key_ssm_param_name="key",
            key_tags={"Key": "Value"},
            cert_ssm_param_name="cert",
            cert_tags={"Key": "Value"},
        )


def test_cert_params_without_critical_should_fail():
    with pytest.raises(ValidationError):
        CertificateParameters(
            key_size=2048,
            validity_days=365,
            country_name="US",
            state_or_province_name="California",
            locality_name="San Francisco",
            organization_name="Example Inc.",
            organizational_unit_name="IT",
            email_address="info@example.com",
            common_name="example.com",
            basic_constraints=BasicConstraints(
                is_critical=False,
                is_ca=True,
                path_length=3,
            ),
            sans=SubjectAlternativeNames(
                is_critical=False,
                dns_names=["example2.com", "example3.com"],
            ),
            key_usage=KeyUsage(
                is_critical=False,
                usages=[KeyUsageEnum.DIGITAL_SIGNATURE, KeyUsageEnum.KEY_ENCIPHERMENT, KeyUsageEnum.KEY_CERT_SIGN]
            ),
            ca_key_ssm_param_name="ca_key",
            ca_cert_ssm_param_name="ca_cert",
            key_ssm_param_name="key",
            key_tags={"Key": "Value"},
            cert_ssm_param_name="cert",
            cert_tags={"Key": "Value"},
        )

def test_cert_params_with_key_cert_sign_key_usage_but_not_ca_should_fail():
    with pytest.raises(ValidationError):
        CertificateParameters(
            key_size=2048,
            validity_days=365,
            country_name="US",
            state_or_province_name="California",
            locality_name="San Francisco",
            organization_name="Example Inc.",
            organizational_unit_name="IT",
            email_address="info@example.com",
            common_name="example.com",
            basic_constraints=BasicConstraints(
                is_critical=False,
                is_ca=False,
                path_length=3,
            ),
            sans=SubjectAlternativeNames(
                is_critical=True,
                dns_names=["example2.com", "example3.com"],
            ),
            key_usage=KeyUsage(
                is_critical=True,
                usages=[KeyUsageEnum.KEY_CERT_SIGN]
            ),
            ca_key_ssm_param_name="ca_key",
            ca_cert_ssm_param_name="ca_cert",
            key_ssm_param_name="key",
            key_tags={"Key": "Value"},
            cert_ssm_param_name="cert",
            cert_tags={"Key": "Value"},
        )


def test_cert_params_with_ca_key_ssm_param_name_but_not_ca_cert_ssm_param_name_should_fail():
    with pytest.raises(ValidationError):
        CertificateParameters(
            key_size=2048,
            validity_days=365,
            country_name="US",
            state_or_province_name="California",
            locality_name="San Francisco",
            organization_name="Example Inc.",
            organizational_unit_name="IT",
            email_address="info@example.com",
            common_name="example.com",
            basic_constraints=BasicConstraints(
                is_critical=True,
                is_ca=True,
                path_length=3,
            ),
            sans=SubjectAlternativeNames(
                is_critical=True,
                dns_names=["example2.com", "example3.com"],
            ),
            key_usage=KeyUsage(
                is_critical=True,
                usages=[KeyUsageEnum.DIGITAL_SIGNATURE, KeyUsageEnum.KEY_ENCIPHERMENT, KeyUsageEnum.KEY_CERT_SIGN]
            ),
            ca_key_ssm_param_name="ca_key",
            ca_cert_ssm_param_name=None,
            key_ssm_param_name="key",
            key_tags={"Key": "Value"},
            cert_ssm_param_name="cert",
            cert_tags={"Key": "Value"},
        )


def test_cert_params_with_ca_cert_ssm_param_name_but_not_ca_key_ssm_param_name_should_fail():
    with pytest.raises(ValidationError):
        CertificateParameters(
            key_size=2048,
            validity_days=365,
            country_name="US",
            state_or_province_name="California",
            locality_name="San Francisco",
            organization_name="Example Inc.",
            organizational_unit_name="IT",
            email_address="info@example.com",
            common_name="example.com",
            basic_constraints=BasicConstraints(
                is_critical=True,
                is_ca=True,
                path_length=3,
            ),
            sans=SubjectAlternativeNames(
                is_critical=True,
                dns_names=["example2.com", "example3.com"],
            ),
            key_usage=KeyUsage(
                is_critical=True,
                usages=[KeyUsageEnum.DIGITAL_SIGNATURE, KeyUsageEnum.KEY_ENCIPHERMENT, KeyUsageEnum.KEY_CERT_SIGN]
            ),
            ca_key_ssm_param_name=None,
            ca_cert_ssm_param_name="ca_cert",
            key_ssm_param_name="key",
            key_tags={"Key": "Value"},
            cert_ssm_param_name="cert",
            cert_tags={"Key": "Value"},
        )


def _create_kms_key() -> str:
    kms_client = boto3.client('kms', region_name="eu-west-1")
    response = kms_client.create_key(Description="Test Key")
    return response['KeyMetadata']['KeyId']


def _load_cert_from_acm(cert_arn: str) -> x509.Certificate:
    acm_client = boto3.client('acm', region_name="eu-west-1")
    pem = acm_client.get_certificate(CertificateArn=cert_arn)['Certificate']
    if isinstance(pem, str):
        pem = pem.encode('utf-8')
    return x509.load_pem_x509_certificate(pem, backend=default_backend())


def _load_chain_from_acm(cert_arn: str) -> str:
    acm_client = boto3.client('acm', region_name="eu-west-1")
    return acm_client.get_certificate(CertificateArn=cert_arn)['CertificateChain']


def _get_ssm_tags(param_name: str) -> dict[str, str]:
    ssm_client = boto3.client('ssm', region_name="eu-west-1")
    resp = ssm_client.list_tags_for_resource(
        ResourceType="Parameter",
        ResourceId=param_name,
    )
    return {tag['Key']: tag['Value'] for tag in resp['TagList']}


def _name_attr(name: x509.Name, oid) -> str:
    return name.get_attributes_for_oid(oid)[0].value


@moto.mock_aws
def test_create_cert_with_good_params_should_succeed(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    cert = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    assert cert is not None


@moto.mock_aws
def test_renew_cert_issued_one_month_ago_should_move_validity_window(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()

    now = datetime.now(timezone.utc)
    one_month_ago = now - timedelta(days=30)

    with freezegun.freeze_time(one_month_ago):
        # Everything inside this block sees `one_month_ago` as the current time
        assert datetime.now(timezone.utc) == one_month_ago
        old_cert = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)

    # X.509 timestamps have a one-second resolution
    assert _load_cert_from_acm(old_cert.cert_arn).not_valid_before_utc == one_month_ago.replace(microsecond=0)

    new_cert = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    assert _load_cert_from_acm(new_cert.cert_arn).not_valid_before_utc >= now.replace(microsecond=0)


# ---------------------------------------------------------------------------
# Certificate content
# ---------------------------------------------------------------------------

@moto.mock_aws
def test_create_cert_subject_and_issuer_for_self_signed(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    result = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    cert = _load_cert_from_acm(result.cert_arn)

    assert _name_attr(cert.subject, NameOID.COUNTRY_NAME) == "US"
    assert _name_attr(cert.subject, NameOID.STATE_OR_PROVINCE_NAME) == "California"
    assert _name_attr(cert.subject, NameOID.LOCALITY_NAME) == "San Francisco"
    assert _name_attr(cert.subject, NameOID.ORGANIZATION_NAME) == "Example Inc."
    assert _name_attr(cert.subject, NameOID.ORGANIZATIONAL_UNIT_NAME) == "IT"
    assert _name_attr(cert.subject, NameOID.EMAIL_ADDRESS) == "info@example.com"
    assert _name_attr(cert.subject, NameOID.COMMON_NAME) == "example.com"
    assert cert.issuer == cert.subject


@moto.mock_aws
def test_create_cert_validity_window_matches_params(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    frozen = datetime(2024, 6, 15, 12, 0, 0, tzinfo=timezone.utc)

    with freezegun.freeze_time(frozen):
        result = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
        cert = _load_cert_from_acm(result.cert_arn)

    assert cert.not_valid_before_utc == frozen.replace(microsecond=0)
    assert cert.not_valid_after_utc == (frozen + timedelta(days=365)).replace(microsecond=0)

    short_params = good_cert_params_self_signed.model_copy(update={"validity_days": 30})
    with freezegun.freeze_time(frozen):
        short_result = create_or_renew_certificate(short_params, kms_key_id)
        short_cert = _load_cert_from_acm(short_result.cert_arn)

    assert short_cert.not_valid_after_utc == (frozen + timedelta(days=30)).replace(microsecond=0)


@moto.mock_aws
def test_create_cert_extensions_match_params(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    result = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    cert = _load_cert_from_acm(result.cert_arn)

    bc_ext = cert.extensions.get_extension_for_oid(ExtensionOID.BASIC_CONSTRAINTS)
    assert bc_ext.critical is True
    assert bc_ext.value.ca is True
    assert bc_ext.value.path_length == 3

    san_ext = cert.extensions.get_extension_for_oid(ExtensionOID.SUBJECT_ALTERNATIVE_NAME)
    assert san_ext.critical is True
    assert set(san_ext.value.get_values_for_type(x509.DNSName)) == {"example2.com", "example3.com"}

    ku_ext = cert.extensions.get_extension_for_oid(ExtensionOID.KEY_USAGE)
    assert ku_ext.critical is True
    assert ku_ext.value.digital_signature is True
    assert ku_ext.value.key_encipherment is True
    assert ku_ext.value.key_cert_sign is True
    assert ku_ext.value.content_commitment is False
    assert ku_ext.value.data_encipherment is False
    assert ku_ext.value.key_agreement is False
    assert ku_ext.value.crl_sign is False
    with pytest.raises(ValueError):
        _ = ku_ext.value.encipher_only
    with pytest.raises(ValueError):
        _ = ku_ext.value.decipher_only


@pytest.mark.parametrize("key_size", [2048, 3072])
@moto.mock_aws
def test_create_cert_key_size(good_cert_params_self_signed: CertificateParameters, key_size: int):
    kms_key_id = _create_kms_key()
    params = good_cert_params_self_signed.model_copy(update={"key_size": key_size})
    result = create_or_renew_certificate(params, kms_key_id)
    cert = _load_cert_from_acm(result.cert_arn)
    assert cert.public_key().key_size == key_size


@moto.mock_aws
def test_create_leaf_cert_basic_constraints_path_length_is_none(
    root_ca_params: CertificateParameters,
    good_cert_params: CertificateParameters,
):
    kms_key_id = _create_kms_key()
    create_or_renew_certificate(root_ca_params, kms_key_id)
    result = create_or_renew_certificate(good_cert_params, kms_key_id)
    cert = _load_cert_from_acm(result.cert_arn)

    bc_ext = cert.extensions.get_extension_for_oid(ExtensionOID.BASIC_CONSTRAINTS)
    assert bc_ext.value.ca is False
    assert bc_ext.value.path_length is None


@moto.mock_aws
def test_create_minimal_cert_params(minimal_cert_params: CertificateParameters):
    kms_key_id = _create_kms_key()
    result = create_or_renew_certificate(minimal_cert_params, kms_key_id)
    cert = _load_cert_from_acm(result.cert_arn)

    assert _name_attr(cert.subject, NameOID.COMMON_NAME) == "minimal.example.com"
    assert len(cert.subject) == 1
    assert cert.issuer == cert.subject

    with pytest.raises(x509.ExtensionNotFound):
        cert.extensions.get_extension_for_oid(ExtensionOID.SUBJECT_ALTERNATIVE_NAME)
    with pytest.raises(x509.ExtensionNotFound):
        cert.extensions.get_extension_for_oid(ExtensionOID.KEY_USAGE)


# ---------------------------------------------------------------------------
# SSM storage
# ---------------------------------------------------------------------------

@moto.mock_aws
def test_create_cert_stores_key_and_cert_in_ssm(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    result = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    ssm_client = boto3.client('ssm', region_name="eu-west-1")

    key_param = ssm_client.get_parameter(
        Name=good_cert_params_self_signed.key_ssm_param_name,
        WithDecryption=True,
    )
    assert key_param['Parameter']['Type'] == 'SecureString'

    described = ssm_client.describe_parameters(
        ParameterFilters=[{
            "Key": "Name",
            "Values": [good_cert_params_self_signed.key_ssm_param_name],
        }]
    )['Parameters'][0]
    assert described['KeyId'] == kms_key_id

    stored_key = Key.model_validate_json(key_param['Parameter']['Value'])
    assert stored_key.cert_arn == result.cert_arn
    assert stored_key.cert_ssm_param == good_cert_params_self_signed.cert_ssm_param_name

    private_key = serialization.load_pem_private_key(
        stored_key.key.encode('utf-8'),
        password=None,
        backend=default_backend(),
    )
    cert = _load_cert_from_acm(result.cert_arn)
    assert private_key.public_key().public_numbers() == cert.public_key().public_numbers()

    cert_param = ssm_client.get_parameter(
        Name=good_cert_params_self_signed.cert_ssm_param_name,
        WithDecryption=True,
    )
    stored_cert = Certificate.model_validate_json(cert_param['Parameter']['Value'])
    assert stored_cert.cert_arn == result.cert_arn
    assert stored_cert.key_ssm_param == good_cert_params_self_signed.key_ssm_param_name
    assert stored_cert.ca_cert_ssm_param is None
    assert stored_cert.ca_key_ssm_param is None


@moto.mock_aws
def test_create_cert_applies_ssm_tags(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)

    assert _get_ssm_tags(good_cert_params_self_signed.key_ssm_param_name) == {"Key": "Value"}
    assert _get_ssm_tags(good_cert_params_self_signed.cert_ssm_param_name) == {"Key": "Value"}


@moto.mock_aws
def test_renew_cert_replaces_ssm_tags(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)

    renewed_params = good_cert_params_self_signed.model_copy(update={
        "key_tags": {"Env": "prod"},
        "cert_tags": {"Env": "prod"},
    })
    create_or_renew_certificate(renewed_params, kms_key_id)

    assert _get_ssm_tags(renewed_params.key_ssm_param_name) == {"Env": "prod"}
    assert _get_ssm_tags(renewed_params.cert_ssm_param_name) == {"Env": "prod"}


# ---------------------------------------------------------------------------
# Renewal
# ---------------------------------------------------------------------------

@moto.mock_aws
def test_renew_cert_reuses_acm_arn(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    first = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    second = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)

    assert first.cert_arn == second.cert_arn

    acm_client = boto3.client('acm', region_name="eu-west-1")
    listed = acm_client.list_certificates()['CertificateSummaryList']
    assert len(listed) == 1
    assert listed[0]['CertificateArn'] == first.cert_arn


@moto.mock_aws
def test_renew_cert_rotates_private_key(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    ssm_client = boto3.client('ssm', region_name="eu-west-1")

    first = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    old_key = Key.model_validate_json(
        ssm_client.get_parameter(
            Name=good_cert_params_self_signed.key_ssm_param_name,
            WithDecryption=True,
        )['Parameter']['Value']
    )

    second = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    new_key = Key.model_validate_json(
        ssm_client.get_parameter(
            Name=good_cert_params_self_signed.key_ssm_param_name,
            WithDecryption=True,
        )['Parameter']['Value']
    )

    assert old_key.key != new_key.key
    assert first.cert_arn == second.cert_arn

    private_key = serialization.load_pem_private_key(
        new_key.key.encode('utf-8'),
        password=None,
        backend=default_backend(),
    )
    cert = _load_cert_from_acm(second.cert_arn)
    assert private_key.public_key().public_numbers() == cert.public_key().public_numbers()


@moto.mock_aws
def test_renew_cert_when_acm_cert_deleted_imports_new_arn(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    first = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)

    acm_client = boto3.client('acm', region_name="eu-west-1")
    acm_client.delete_certificate(CertificateArn=first.cert_arn)

    second = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    assert second.cert_arn != first.cert_arn

    ssm_client = boto3.client('ssm', region_name="eu-west-1")
    stored_cert = Certificate.model_validate_json(
        ssm_client.get_parameter(
            Name=good_cert_params_self_signed.cert_ssm_param_name,
            WithDecryption=True,
        )['Parameter']['Value']
    )
    assert stored_cert.cert_arn == second.cert_arn


# ---------------------------------------------------------------------------
# CA signing / chaining
# ---------------------------------------------------------------------------

@moto.mock_aws
def test_create_ca_signed_leaf_cert(
    root_ca_params: CertificateParameters,
    good_cert_params: CertificateParameters,
):
    kms_key_id = _create_kms_key()
    ca_result = create_or_renew_certificate(root_ca_params, kms_key_id)
    ca_cert = _load_cert_from_acm(ca_result.cert_arn)

    leaf_result = create_or_renew_certificate(good_cert_params, kms_key_id)
    leaf_cert = _load_cert_from_acm(leaf_result.cert_arn)

    assert leaf_cert.issuer == ca_cert.subject
    assert leaf_result.ca_cert_ssm_param == "ca_cert"
    assert leaf_result.ca_key_ssm_param == "ca_key"

    ca_cert.public_key().verify(
        leaf_cert.signature,
        leaf_cert.tbs_certificate_bytes,
        padding.PKCS1v15(),
        leaf_cert.signature_hash_algorithm,
    )


@moto.mock_aws
def test_create_ca_signed_leaf_chain_contains_ca(
    root_ca_params: CertificateParameters,
    good_cert_params: CertificateParameters,
):
    kms_key_id = _create_kms_key()
    ca_result = create_or_renew_certificate(root_ca_params, kms_key_id)
    leaf_result = create_or_renew_certificate(good_cert_params, kms_key_id)

    ca_pem = boto3.client('acm', region_name="eu-west-1").get_certificate(
        CertificateArn=ca_result.cert_arn
    )['Certificate']
    chain = _load_chain_from_acm(leaf_result.cert_arn)
    assert ca_pem in chain


@moto.mock_aws
def test_create_root_intermediate_leaf_chain(
    root_ca_params: CertificateParameters,
    intermediate_ca_params: CertificateParameters,
    good_cert_params: CertificateParameters,
):
    kms_key_id = _create_kms_key()
    root_result = create_or_renew_certificate(root_ca_params, kms_key_id)
    int_result = create_or_renew_certificate(intermediate_ca_params, kms_key_id)

    leaf_params = good_cert_params.model_copy(update={
        "ca_key_ssm_param_name": "int_key",
        "ca_cert_ssm_param_name": "int_cert",
    })
    leaf_result = create_or_renew_certificate(leaf_params, kms_key_id)

    acm_client = boto3.client('acm', region_name="eu-west-1")
    root_pem = acm_client.get_certificate(CertificateArn=root_result.cert_arn)['Certificate']
    int_pem = acm_client.get_certificate(CertificateArn=int_result.cert_arn)['Certificate']
    chain = _load_chain_from_acm(leaf_result.cert_arn)

    assert int_pem in chain
    assert root_pem in chain
    assert chain.index(int_pem) < chain.index(root_pem)


# ---------------------------------------------------------------------------
# Rollback on failure
# ---------------------------------------------------------------------------

@moto.mock_aws
def test_rollback_when_key_save_fails(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    acm_client = boto3.client('acm', region_name="eu-west-1")

    with mock.patch("certificate._upsert_ssm_param", side_effect=RuntimeError("key save failed")):
        with pytest.raises(RuntimeError, match="key save failed"):
            create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)

    assert acm_client.list_certificates()['CertificateSummaryList'] == []


@moto.mock_aws
def test_rollback_when_cert_save_fails(good_cert_params_self_signed: CertificateParameters):
    kms_key_id = _create_kms_key()
    acm_client = boto3.client('acm', region_name="eu-west-1")
    ssm_client = boto3.client('ssm', region_name="eu-west-1")

    call_count = {"n": 0}

    def side_effect(*args, **kwargs):
        call_count["n"] += 1
        if call_count["n"] == 1:
            return _upsert_ssm_param(*args, **kwargs)
        raise RuntimeError("cert save failed")

    with mock.patch("certificate._upsert_ssm_param", side_effect=side_effect):
        with pytest.raises(RuntimeError, match="cert save failed"):
            create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)

    assert acm_client.list_certificates()['CertificateSummaryList'] == []
    with pytest.raises(ssm_client.exceptions.ParameterNotFound):
        ssm_client.get_parameter(Name=good_cert_params_self_signed.key_ssm_param_name)
