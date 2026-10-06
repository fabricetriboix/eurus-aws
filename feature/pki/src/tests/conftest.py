import os

# Set global environment variables before importing certificate, which reads AWS_REGION at import time.
os.environ['AWS_REGION'] = "eu-west-1"
os.environ['AWS_DEFAULT_REGION'] = "eu-west-1"
os.environ['PKI_BUCKET_NAME'] = "test-pki"

import boto3
import moto
import pytest

from certificate import (
    CertificateParameters,
    BasicConstraints,
    SubjectAlternativeNames,
    KeyUsage,
    KeyUsageEnum
)


@pytest.fixture(autouse=True)
def pki_bucket():
    """Provide a versioned PKI bucket. Versioning is required because saves return a version id."""
    with moto.mock_aws():
        s3_client = boto3.client('s3', region_name="eu-west-1")
        s3_client.create_bucket(
            Bucket=os.environ['PKI_BUCKET_NAME'],
            CreateBucketConfiguration={'LocationConstraint': "eu-west-1"},
        )
        s3_client.put_bucket_versioning(
            Bucket=os.environ['PKI_BUCKET_NAME'],
            VersioningConfiguration={'Status': "Enabled"},
        )
        yield


@pytest.fixture(scope="function")
def good_cert_params() -> CertificateParameters:
    return CertificateParameters(
        name="leaf",
        key_type="RSA",
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
        ca_name="root-ca",
    )

@pytest.fixture(scope="function")
def good_cert_params_self_signed() -> CertificateParameters:
    return CertificateParameters(
        name="self-signed",
        key_type="RSA",
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
    )


@pytest.fixture(scope="function")
def root_ca_params() -> CertificateParameters:
    return CertificateParameters(
        name="root-ca",
        key_type="RSA",
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
    )


@pytest.fixture(scope="function")
def intermediate_ca_params() -> CertificateParameters:
    return CertificateParameters(
        name="intermediate-ca",
        key_type="RSA",
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
        ca_name="root-ca",
    )


@pytest.fixture(scope="function")
def minimal_cert_params() -> CertificateParameters:
    return CertificateParameters(
        name="minimal",
        key_size=2048,
        validity_days=365,
        common_name="minimal.example.com",
        basic_constraints=BasicConstraints(
            is_critical=True,
            is_ca=False,
            path_length=1,
        ),
    )
