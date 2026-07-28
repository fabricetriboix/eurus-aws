# PKI

This feature implements a fully-functioning public key infrastructure
on AWS using only serverless AWS services. It also automatically
renews certificates that are about to expire, and handle the renewal
of dependent certificates (for example, if a CA certificate is about
to be renewed, all dependent certificates will also be renewed).

It is limited in scope. In particular, it expects the common name and
the SANs to be DNS names only. It only supports RSA encryption.

## Data structures

Keys and certificates are stored in SSM Parameter Store as parameters
encrypted using a dedicated KMS key. Please note that in the case of
certificates, only metadata is stored as storing the certificate and
chain would likely exceed the limits for SSM parameters maximum size
of 4KB. Parameters storing key information and parameters storing
certificates are stored in different directory structures, in order to
allow fine-grained permissions (eg: allow access to the certificate
but not the key). For example:

    /org/project/pki/keys
    /org/project/pki/certs

A key parameter is a JSON object structured like so:

```json
{
  "cert_arn": "ARN_OF_CERT_IN_ACM",
  "cert_ssm_param": "SSM_PARAM_FOR_CERT",
  "key": "PEM_ENCODED_KEY"
}
```

A certificate parameter is a JSON object structured like so:

```json
{
  "cert_arn": "ARN_OF_CERT_IN_ACM",
  "key_ssm_param": "SSM_PARAM_FOR_KEY",
  "ca_cert_ssm_param": "SSM_PARAM_FOR_CA_CERT",
  "ca_key_ssm_param": "SSM_PARAM_FOR_CA_KEY"
}
```

Please note the `ca_cert_ssm_param` and `ca_key_ssm_param` will be
`null` for self-signed certificates (such as root CA certificates).
