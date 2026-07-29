import pytest
import moto
import boto3
import freezegun

from datetime import datetime, timezone, timedelta
from pydantic import ValidationError
from cryptography import x509
from cryptography.hazmat.backends import default_backend

from certificate import (
    CertificateParameters,
    BasicConstraints,
    SubjectAlternativeNames,
    KeyUsage,
    KeyUsageEnum,
    create_or_renew_certificate,
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


@moto.mock_aws
def test_create_cert_with_good_params_should_succeed(good_cert_params_self_signed: CertificateParameters):
    kms_client = boto3.client('kms', region_name="eu-west-1")
    response = kms_client.create_key(Description="Test Key")
    kms_key_id = response['KeyMetadata']['KeyId']
    cert = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    assert cert is not None


@moto.mock_aws
def test_renew_cert_with_good_params_should_succeed(good_cert_params_self_signed: CertificateParameters):
    kms_client = boto3.client('kms', region_name="eu-west-1")
    response = kms_client.create_key(Description="Test Key")
    kms_key_id = response['KeyMetadata']['KeyId']
    cert = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    assert cert is not None

    cert = create_or_renew_certificate(good_cert_params_self_signed, kms_key_id)
    assert cert is not None


def _load_cert_from_acm(cert_arn: str) -> x509.Certificate:
    acm_client = boto3.client('acm', region_name="eu-west-1")
    pem = acm_client.get_certificate(CertificateArn=cert_arn)['Certificate']
    if isinstance(pem, str):
        pem = pem.encode('utf-8')
    return x509.load_pem_x509_certificate(pem, backend=default_backend())


@moto.mock_aws
def test_renew_cert_issued_one_month_ago_should_move_validity_window(good_cert_params_self_signed: CertificateParameters):
    kms_client = boto3.client('kms', region_name="eu-west-1")
    response = kms_client.create_key(Description="Test Key")
    kms_key_id = response['KeyMetadata']['KeyId']

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
