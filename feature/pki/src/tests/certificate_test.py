import os

import pytest
import boto3
import freezegun
from unittest import mock

from datetime import datetime, timezone, timedelta
from pydantic import ValidationError
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec, padding
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
    _save_to_s3,
)


def test_good_cert_param_should_succeed(good_cert_params: CertificateParameters):
    assert good_cert_params.model_dump() == {
        "name": "leaf",
        "key_type": "RSA",
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
        "ca_name": "root-ca",
    }


def test_cert_params_with_invalid_key_size_should_fail():
    with pytest.raises(ValidationError):
        CertificateParameters(
            name="invalid-size",
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
        )


def test_cert_params_with_invalid_key_type_should_fail():
    with pytest.raises(ValidationError):
        CertificateParameters(
            name="invalid-type",
            key_type="DSA",
            key_size=2048,
            validity_days=365,
            common_name="example.com",
            basic_constraints=BasicConstraints(
                is_critical=True,
                is_ca=False,
            ),
        )


@pytest.mark.parametrize("key_size", [256, 384, 521])
def test_ecdsa_key_sizes_should_succeed(key_size: int):
    params = CertificateParameters(
        name="ecdsa",
        key_type="ECDSA",
        key_size=key_size,
        validity_days=365,
        common_name="ecdsa.example.com",
        basic_constraints=BasicConstraints(
            is_critical=True,
            is_ca=False,
        ),
    )
    assert params.key_type == "ECDSA"
    assert params.key_size == key_size


def test_cert_params_without_critical_should_fail():
    with pytest.raises(ValidationError):
        CertificateParameters(
            name="not-critical",
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
        )

def test_cert_params_with_key_cert_sign_key_usage_but_not_ca_should_fail():
    with pytest.raises(ValidationError):
        CertificateParameters(
            name="key-cert-sign",
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
        )


def _load_cert_from_acm(cert_arn: str) -> x509.Certificate:
    acm_client = boto3.client('acm', region_name="eu-west-1")
    pem = acm_client.get_certificate(CertificateArn=cert_arn)['Certificate']
    if isinstance(pem, str):
        pem = pem.encode('utf-8')
    return x509.load_pem_x509_certificate(pem, backend=default_backend())


def _load_chain_from_acm(cert_arn: str) -> str:
    acm_client = boto3.client('acm', region_name="eu-west-1")
    return acm_client.get_certificate(CertificateArn=cert_arn)['CertificateChain']


def _s3_client():
    return boto3.client('s3', region_name="eu-west-1")


def _key_object_key(name: str) -> str:
    return f"pki/keys/{name}.key.json"


def _cert_object_key(name: str) -> str:
    return f"pki/certs/{name}.crt.json"


def _read_s3_object(key: str) -> str:
    response = _s3_client().get_object(
        Bucket=os.environ['PKI_BUCKET_NAME'],
        Key=key,
    )
    return response['Body'].read().decode('utf-8')


def _name_attr(name: x509.Name, oid) -> str:
    return name.get_attributes_for_oid(oid)[0].value


def test_create_cert_with_good_params_should_succeed(good_cert_params_self_signed: CertificateParameters):
    cert = create_or_renew_certificate(good_cert_params_self_signed)
    assert cert is not None


def test_renew_cert_issued_one_month_ago_should_move_validity_window(good_cert_params_self_signed: CertificateParameters):
    now = datetime.now(timezone.utc)
    one_month_ago = now - timedelta(days=30)

    with freezegun.freeze_time(one_month_ago):
        # Everything inside this block sees `one_month_ago` as the current time
        assert datetime.now(timezone.utc) == one_month_ago
        old_cert = create_or_renew_certificate(good_cert_params_self_signed)

    # X.509 timestamps have a one-second resolution
    assert _load_cert_from_acm(old_cert.cert_arn).not_valid_before_utc == one_month_ago.replace(microsecond=0)

    new_cert = create_or_renew_certificate(good_cert_params_self_signed)
    assert _load_cert_from_acm(new_cert.cert_arn).not_valid_before_utc >= now.replace(microsecond=0)


# ---------------------------------------------------------------------------
# Certificate content
# ---------------------------------------------------------------------------

def test_create_cert_subject_and_issuer_for_self_signed(good_cert_params_self_signed: CertificateParameters):
    result = create_or_renew_certificate(good_cert_params_self_signed)
    cert = _load_cert_from_acm(result.cert_arn)

    assert _name_attr(cert.subject, NameOID.COUNTRY_NAME) == "US"
    assert _name_attr(cert.subject, NameOID.STATE_OR_PROVINCE_NAME) == "California"
    assert _name_attr(cert.subject, NameOID.LOCALITY_NAME) == "San Francisco"
    assert _name_attr(cert.subject, NameOID.ORGANIZATION_NAME) == "Example Inc."
    assert _name_attr(cert.subject, NameOID.ORGANIZATIONAL_UNIT_NAME) == "IT"
    assert _name_attr(cert.subject, NameOID.EMAIL_ADDRESS) == "info@example.com"
    assert _name_attr(cert.subject, NameOID.COMMON_NAME) == "example.com"
    assert cert.issuer == cert.subject


def test_create_cert_validity_window_matches_params(good_cert_params_self_signed: CertificateParameters):
    frozen = datetime(2024, 6, 15, 12, 0, 0, tzinfo=timezone.utc)

    with freezegun.freeze_time(frozen):
        result = create_or_renew_certificate(good_cert_params_self_signed)
        cert = _load_cert_from_acm(result.cert_arn)

    assert cert.not_valid_before_utc == frozen.replace(microsecond=0)
    assert cert.not_valid_after_utc == (frozen + timedelta(days=365)).replace(microsecond=0)

    short_params = good_cert_params_self_signed.model_copy(update={"validity_days": 30})
    with freezegun.freeze_time(frozen):
        short_result = create_or_renew_certificate(short_params)
        short_cert = _load_cert_from_acm(short_result.cert_arn)

    assert short_cert.not_valid_after_utc == (frozen + timedelta(days=30)).replace(microsecond=0)


def test_create_cert_extensions_match_params(good_cert_params_self_signed: CertificateParameters):
    result = create_or_renew_certificate(good_cert_params_self_signed)
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


@pytest.mark.parametrize("key_size", [2048, 3072, 4096])
def test_create_cert_key_size(good_cert_params_self_signed: CertificateParameters, key_size: int):
    params = good_cert_params_self_signed.model_copy(update={"key_size": key_size})
    result = create_or_renew_certificate(params)
    cert = _load_cert_from_acm(result.cert_arn)
    assert cert.public_key().key_size == key_size


@pytest.mark.parametrize("key_size,curve_name", [
    (256, "secp256r1"),
    (384, "secp384r1"),
    (521, "secp521r1"),
])
def test_create_ecdsa_cert(
    good_cert_params_self_signed: CertificateParameters,
    key_size: int,
    curve_name: str,
):
    params = good_cert_params_self_signed.model_copy(update={
        "key_type": "ECDSA",
        "key_size": key_size,
    })
    result = create_or_renew_certificate(params)
    cert = _load_cert_from_acm(result.cert_arn)

    assert isinstance(cert.public_key(), ec.EllipticCurvePublicKey)
    assert cert.public_key().curve.name == curve_name
    assert cert.public_key().key_size == key_size

    stored_key = Key.model_validate_json(_read_s3_object(_key_object_key(params.name)))
    private_key = serialization.load_pem_private_key(
        stored_key.key_pem.encode('utf-8'),
        password=None,
        backend=default_backend(),
    )
    assert isinstance(private_key, ec.EllipticCurvePrivateKey)
    assert private_key.curve.name == curve_name
    assert private_key.public_key().public_numbers() == cert.public_key().public_numbers()


def test_rsa_with_ecdsa_key_size_should_fail(good_cert_params_self_signed: CertificateParameters):
    params = good_cert_params_self_signed.model_copy(update={"key_type": "RSA", "key_size": 256})
    with pytest.raises(ValueError, match="Invalid key size"):
        create_or_renew_certificate(params)


def test_ecdsa_with_rsa_key_size_should_fail(good_cert_params_self_signed: CertificateParameters):
    params = good_cert_params_self_signed.model_copy(update={"key_type": "ECDSA", "key_size": 2048})
    with pytest.raises(ValueError, match="Invalid key size"):
        create_or_renew_certificate(params)


def test_create_leaf_cert_basic_constraints_path_length_is_none(
    root_ca_params: CertificateParameters,
    good_cert_params: CertificateParameters,
):
    create_or_renew_certificate(root_ca_params)
    result = create_or_renew_certificate(good_cert_params)
    cert = _load_cert_from_acm(result.cert_arn)

    bc_ext = cert.extensions.get_extension_for_oid(ExtensionOID.BASIC_CONSTRAINTS)
    assert bc_ext.value.ca is False
    assert bc_ext.value.path_length is None


def test_create_minimal_cert_params(minimal_cert_params: CertificateParameters):
    result = create_or_renew_certificate(minimal_cert_params)
    cert = _load_cert_from_acm(result.cert_arn)

    assert _name_attr(cert.subject, NameOID.COMMON_NAME) == "minimal.example.com"
    assert len(cert.subject) == 1
    assert cert.issuer == cert.subject

    with pytest.raises(x509.ExtensionNotFound):
        cert.extensions.get_extension_for_oid(ExtensionOID.SUBJECT_ALTERNATIVE_NAME)
    with pytest.raises(x509.ExtensionNotFound):
        cert.extensions.get_extension_for_oid(ExtensionOID.KEY_USAGE)


# ---------------------------------------------------------------------------
# S3 storage
# ---------------------------------------------------------------------------

def test_create_cert_stores_key_and_cert_in_s3(good_cert_params_self_signed: CertificateParameters):
    result = create_or_renew_certificate(good_cert_params_self_signed)

    stored_key = Key.model_validate_json(_read_s3_object(_key_object_key(good_cert_params_self_signed.name)))
    assert stored_key.name == good_cert_params_self_signed.name
    assert stored_key.cert_arn == result.cert_arn

    private_key = serialization.load_pem_private_key(
        stored_key.key_pem.encode('utf-8'),
        password=None,
        backend=default_backend(),
    )
    cert = _load_cert_from_acm(result.cert_arn)
    assert private_key.public_key().public_numbers() == cert.public_key().public_numbers()

    stored_cert = Certificate.model_validate_json(_read_s3_object(_cert_object_key(good_cert_params_self_signed.name)))
    assert stored_cert.name == good_cert_params_self_signed.name
    assert stored_cert.cert_arn == result.cert_arn
    assert stored_cert.ca_name is None


# ---------------------------------------------------------------------------
# Renewal
# ---------------------------------------------------------------------------

def test_renew_cert_reuses_acm_arn(good_cert_params_self_signed: CertificateParameters):
    first = create_or_renew_certificate(good_cert_params_self_signed)
    second = create_or_renew_certificate(good_cert_params_self_signed)

    assert first.cert_arn == second.cert_arn

    acm_client = boto3.client('acm', region_name="eu-west-1")
    listed = acm_client.list_certificates()['CertificateSummaryList']
    assert len(listed) == 1
    assert listed[0]['CertificateArn'] == first.cert_arn


def test_renew_cert_rotates_private_key(good_cert_params_self_signed: CertificateParameters):
    first = create_or_renew_certificate(good_cert_params_self_signed)
    old_key = Key.model_validate_json(_read_s3_object(_key_object_key(good_cert_params_self_signed.name)))

    second = create_or_renew_certificate(good_cert_params_self_signed)
    new_key = Key.model_validate_json(_read_s3_object(_key_object_key(good_cert_params_self_signed.name)))

    assert old_key.key_pem != new_key.key_pem
    assert first.cert_arn == second.cert_arn

    private_key = serialization.load_pem_private_key(
        new_key.key_pem.encode('utf-8'),
        password=None,
        backend=default_backend(),
    )
    cert = _load_cert_from_acm(second.cert_arn)
    assert private_key.public_key().public_numbers() == cert.public_key().public_numbers()


def test_renew_cert_when_acm_cert_deleted_imports_new_arn(good_cert_params_self_signed: CertificateParameters):
    first = create_or_renew_certificate(good_cert_params_self_signed)

    acm_client = boto3.client('acm', region_name="eu-west-1")
    acm_client.delete_certificate(CertificateArn=first.cert_arn)

    second = create_or_renew_certificate(good_cert_params_self_signed)
    assert second.cert_arn != first.cert_arn

    stored_cert = Certificate.model_validate_json(_read_s3_object(_cert_object_key(good_cert_params_self_signed.name)))
    assert stored_cert.cert_arn == second.cert_arn


# ---------------------------------------------------------------------------
# CA signing / chaining
# ---------------------------------------------------------------------------

def test_create_ca_signed_leaf_cert(
    root_ca_params: CertificateParameters,
    good_cert_params: CertificateParameters,
):
    ca_result = create_or_renew_certificate(root_ca_params)
    ca_cert = _load_cert_from_acm(ca_result.cert_arn)

    leaf_result = create_or_renew_certificate(good_cert_params)
    leaf_cert = _load_cert_from_acm(leaf_result.cert_arn)

    assert leaf_cert.issuer == ca_cert.subject
    assert leaf_result.ca_name == root_ca_params.name

    stored_leaf = Certificate.model_validate_json(_read_s3_object(_cert_object_key(good_cert_params.name)))
    assert stored_leaf.ca_name == root_ca_params.name

    ca_cert.public_key().verify(
        leaf_cert.signature,
        leaf_cert.tbs_certificate_bytes,
        padding.PKCS1v15(),
        leaf_cert.signature_hash_algorithm,
    )


def test_create_ecdsa_ca_signed_leaf_cert(
    root_ca_params: CertificateParameters,
    good_cert_params: CertificateParameters,
):
    root_params = root_ca_params.model_copy(update={"key_type": "ECDSA", "key_size": 256})
    leaf_params = good_cert_params.model_copy(update={"key_type": "ECDSA", "key_size": 256})

    ca_result = create_or_renew_certificate(root_params)
    ca_cert = _load_cert_from_acm(ca_result.cert_arn)

    leaf_result = create_or_renew_certificate(leaf_params)
    leaf_cert = _load_cert_from_acm(leaf_result.cert_arn)

    assert leaf_cert.issuer == ca_cert.subject
    assert isinstance(leaf_cert.public_key(), ec.EllipticCurvePublicKey)
    ca_cert.public_key().verify(
        leaf_cert.signature,
        leaf_cert.tbs_certificate_bytes,
        ec.ECDSA(leaf_cert.signature_hash_algorithm),
    )


def test_create_ca_signed_leaf_chain_contains_ca(
    root_ca_params: CertificateParameters,
    good_cert_params: CertificateParameters,
):
    ca_result = create_or_renew_certificate(root_ca_params)
    leaf_result = create_or_renew_certificate(good_cert_params)

    ca_pem = boto3.client('acm', region_name="eu-west-1").get_certificate(
        CertificateArn=ca_result.cert_arn
    )['Certificate']
    chain = _load_chain_from_acm(leaf_result.cert_arn)
    assert ca_pem in chain


def test_create_root_intermediate_leaf_chain(
    root_ca_params: CertificateParameters,
    intermediate_ca_params: CertificateParameters,
    good_cert_params: CertificateParameters,
):
    root_result = create_or_renew_certificate(root_ca_params)
    int_result = create_or_renew_certificate(intermediate_ca_params)

    leaf_params = good_cert_params.model_copy(update={"ca_name": intermediate_ca_params.name})
    leaf_result = create_or_renew_certificate(leaf_params)

    acm_client = boto3.client('acm', region_name="eu-west-1")
    root_pem = acm_client.get_certificate(CertificateArn=root_result.cert_arn)['Certificate']
    int_pem = acm_client.get_certificate(CertificateArn=int_result.cert_arn)['Certificate']
    chain = _load_chain_from_acm(leaf_result.cert_arn)

    assert int_pem in chain
    assert root_pem in chain
    assert chain.index(int_pem) < chain.index(root_pem)
    assert leaf_result.ca_name == intermediate_ca_params.name


# ---------------------------------------------------------------------------
# Rollback on failure
# ---------------------------------------------------------------------------

def test_rollback_when_key_save_fails(good_cert_params_self_signed: CertificateParameters):
    acm_client = boto3.client('acm', region_name="eu-west-1")

    with mock.patch("certificate._save_to_s3", side_effect=RuntimeError("key save failed")):
        with pytest.raises(RuntimeError, match="key save failed"):
            create_or_renew_certificate(good_cert_params_self_signed)

    assert acm_client.list_certificates()['CertificateSummaryList'] == []
    with pytest.raises(_s3_client().exceptions.NoSuchKey):
        _read_s3_object(_key_object_key(good_cert_params_self_signed.name))
    with pytest.raises(_s3_client().exceptions.NoSuchKey):
        _read_s3_object(_cert_object_key(good_cert_params_self_signed.name))


def test_rollback_when_cert_save_fails(good_cert_params_self_signed: CertificateParameters):
    acm_client = boto3.client('acm', region_name="eu-west-1")

    call_count = {"n": 0}

    def side_effect(*args, **kwargs):
        call_count["n"] += 1
        if call_count["n"] == 1:
            return _save_to_s3(*args, **kwargs)
        raise RuntimeError("cert save failed")

    with mock.patch("certificate._save_to_s3", side_effect=side_effect):
        with pytest.raises(RuntimeError, match="cert save failed"):
            create_or_renew_certificate(good_cert_params_self_signed)

    assert acm_client.list_certificates()['CertificateSummaryList'] == []
    with pytest.raises(_s3_client().exceptions.NoSuchKey):
        _read_s3_object(_key_object_key(good_cert_params_self_signed.name))
    with pytest.raises(_s3_client().exceptions.NoSuchKey):
        _read_s3_object(_cert_object_key(good_cert_params_self_signed.name))


def test_rollback_when_cert_save_fails_during_renewal(good_cert_params_self_signed: CertificateParameters):
    first = create_or_renew_certificate(good_cert_params_self_signed)
    original_key = Key.model_validate_json(_read_s3_object(_key_object_key(good_cert_params_self_signed.name)))
    original_cert = _load_cert_from_acm(first.cert_arn)

    call_count = {"n": 0}

    def side_effect(*args, **kwargs):
        call_count["n"] += 1
        if call_count["n"] == 1:
            return _save_to_s3(*args, **kwargs)
        raise RuntimeError("cert save failed")

    with mock.patch("certificate._save_to_s3", side_effect=side_effect):
        with pytest.raises(RuntimeError, match="cert save failed"):
            create_or_renew_certificate(good_cert_params_self_signed)

    restored_key = Key.model_validate_json(_read_s3_object(_key_object_key(good_cert_params_self_signed.name)))
    assert restored_key.key_pem == original_key.key_pem

    restored_cert = _load_cert_from_acm(first.cert_arn)
    assert restored_cert.public_key().public_numbers() == original_cert.public_key().public_numbers()

    stored_cert = Certificate.model_validate_json(_read_s3_object(_cert_object_key(good_cert_params_self_signed.name)))
    assert stored_cert.cert_arn == first.cert_arn
