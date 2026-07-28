import pytest

from pydantic import ValidationError

from certificate import (
    CertificateParameters,
    BasicConstraints,
    SubjectAlternativeNames,
    KeyUsage,
    KeyUsageEnum
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
            "is_ca": True,
            "path_length": 3,
        },
        "sans": {
            "is_critical": True,
            "dns_names": ["example2.com", "example3.com"],
        },
        "key_usage": {
            "is_critical": True,
            "usages": [
                KeyUsageEnum.DIGITAL_SIGNATURE,
                KeyUsageEnum.KEY_ENCIPHERMENT,
                KeyUsageEnum.KEY_CERT_SIGN
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
