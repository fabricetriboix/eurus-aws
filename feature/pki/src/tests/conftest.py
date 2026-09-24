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


@pytest.fixture(scope="function")
def root_ca_params() -> CertificateParameters:
    return CertificateParameters(
        key_size=2048,
        validity_days=3650,
        country_name="US",
        state_or_province_name="California",
        locality_name="San Francisco",
        organization_name="Example Inc.",
        organizational_unit_name="IT",
        email_address="ca@example.com",
        common_name="Example Root CA",
        basic_constraints=BasicConstraints(
            is_critical=True,
            is_ca=True,
            path_length=3,
        ),
        key_usage=KeyUsage(
            is_critical=True,
            usages=[KeyUsageEnum.KEY_CERT_SIGN],
        ),
        key_ssm_param_name="ca_key",
        key_tags={"Role": "RootCA"},
        cert_ssm_param_name="ca_cert",
        cert_tags={"Role": "RootCA"},
    )


@pytest.fixture(scope="function")
def intermediate_ca_params() -> CertificateParameters:
    return CertificateParameters(
        key_size=2048,
        validity_days=1825,
        country_name="US",
        state_or_province_name="California",
        locality_name="San Francisco",
        organization_name="Example Inc.",
        organizational_unit_name="IT",
        email_address="int-ca@example.com",
        common_name="Example Intermediate CA",
        basic_constraints=BasicConstraints(
            is_critical=True,
            is_ca=True,
            path_length=1,
        ),
        key_usage=KeyUsage(
            is_critical=True,
            usages=[KeyUsageEnum.KEY_CERT_SIGN],
        ),
        ca_key_ssm_param_name="ca_key",
        ca_cert_ssm_param_name="ca_cert",
        key_ssm_param_name="int_key",
        key_tags={"Role": "IntermediateCA"},
        cert_ssm_param_name="int_cert",
        cert_tags={"Role": "IntermediateCA"},
    )


@pytest.fixture(scope="function")
def minimal_cert_params() -> CertificateParameters:
    return CertificateParameters(
        key_size=2048,
        validity_days=365,
        common_name="minimal.example.com",
        basic_constraints=BasicConstraints(
            is_critical=True,
            is_ca=False,
            path_length=1,
        ),
        key_ssm_param_name="minimal_key",
        cert_ssm_param_name="minimal_cert",
    )
