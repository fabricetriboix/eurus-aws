import os

# Set global environment variables
os.environ['AWS_REGION'] = "eu-west-1"

import pytest

from certificate import (
    CertificateParameters,
    BasicConstraints,
    SubjectAlternativeNames,
    KeyUsage,
    KeyUsageEnum
)


@pytest.fixture(scope="function")
def good_cert_params() -> CertificateParameters:
    return CertificateParameters(
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
            is_ca=False,
            path_length=3,
        ),
        sans=SubjectAlternativeNames(
            is_critical=False,
            dns_names=["example2.com", "example3.com"],
        ),
        key_usage=KeyUsage(
            is_critical=True,
            usages=[KeyUsageEnum.DIGITAL_SIGNATURE, KeyUsageEnum.KEY_ENCIPHERMENT]
        ),
        ca_key_ssm_param_name="ca_key",
        ca_cert_ssm_param_name="ca_cert",
        key_ssm_param_name="key",
        key_tags={"Key": "Value"},
        cert_ssm_param_name="cert",
        cert_tags={"Key": "Value"},
    )

@pytest.fixture(scope="function")
def good_cert_params_self_signed() -> CertificateParameters:
    return CertificateParameters(
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
        key_ssm_param_name="key",
        key_tags={"Key": "Value"},
        cert_ssm_param_name="cert",
        cert_tags={"Key": "Value"},
    )
