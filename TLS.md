# 🔐 Mutual TLS (mTLS) for DICOM Communications

This guide explains how to set up **mutual TLS authentication** for secure DICOM communications between an SCU (client) and IRIS (SCP/server).

---

## 🧠 What is mTLS?

In standard TLS, only the **server** proves its identity to the client. With **mutual TLS (mTLS)**, both parties authenticate each other using certificates:

- The **server** presents a certificate to prove it's legitimate
- The **client** also presents a certificate to prove its identity
- Both certificates are signed by a trusted **Certificate Authority (CA)**

This is especially important in healthcare environments where you need to ensure only authorized imaging devices can send DICOM data.

---

## 🗂️ Certificate Structure

For this example, we use a **single CA** that signs both server and client certificates:

```
shared/pki/
├── ca/
│   ├── ca.key              # CA private key (keep secure!)
│   └── ca.crt              # CA certificate (goes in trust stores)
├── server/
│   ├── server.key          # Server private key
│   ├── server.csr          # Server certificate signing request
│   └── server.crt          # Server certificate
└── clients/
    └── dcm1/
        ├── scu1.key        # Client private key
        ├── scu1.csr        # Client CSR
        ├── scu1.crt        # Client certificate
        ├── scu1.p12        # Client keystore (for storescu)
        └── truststore.p12  # Trust store with CA cert
```

> **Production Note**: In real-world scenarios, consider using **intermediate CAs** instead of signing certificates directly with the root CA. This allows you to keep the root CA offline and secure, revoke intermediate CAs if compromised, and separate trust domains (e.g., different CAs for clients vs servers). See the end of this document for more details.

---

## 1️⃣ Create the Certificate Authority

```bash
mkdir -p shared/pki/ca
cd shared/pki/ca
```

### Generate CA private key

```bash
openssl genrsa -out ca.key 4096
```

### Create self-signed CA certificate

```bash
openssl req -x509 -new -key ca.key -days 3650 -sha256 \
  -subj "/C=ES/O=Demo/OU=DICOM/CN=Demo DICOM CA" \
  -out ca.crt
```

---

## 2️⃣ Create the Server Certificate (SCP)

```bash
mkdir -p shared/pki/server
cd shared/pki/server
```

### Generate server private key

```bash
openssl genrsa -out server.key 2048
```

### Create server CSR

```bash
openssl req -new -key server.key \
  -subj "/C=ES/O=Demo/OU=DICOM/CN=iris" \
  -out server.csr
```

> **Important**: `CN=iris` must match the hostname the client uses to connect.

### Sign server certificate with CA

```bash
openssl x509 -req -in server.csr \
  -CA ../ca/ca.crt -CAkey ../ca/ca.key -CAcreateserial \
  -out server.crt -days 825 -sha256 \
  -extfile <(printf "extendedKeyUsage=serverAuth\nsubjectAltName=DNS:iris")
```

---

## 3️⃣ Create the Client Certificate (SCU)

```bash
mkdir -p shared/pki/clients/dcm1
cd shared/pki/clients/dcm1
```

### Generate client private key

```bash
openssl genrsa -out scu1.key 2048
```

### Create client CSR

```bash
openssl req -new -key scu1.key \
  -subj "/C=ES/O=Demo/OU=DICOM/CN=SCU_DCM1" \
  -out scu1.csr
```

### Sign client certificate with CA

```bash
openssl x509 -req -in scu1.csr \
  -CA ../../ca/ca.crt -CAkey ../../ca/ca.key -CAcreateserial \
  -out scu1.crt -days 825 -sha256 \
  -extfile <(printf "extendedKeyUsage=clientAuth")
```

---

## 4️⃣ Create Client Keystore (PKCS#12)

The `storescu` tool from dcm4che cannot use PEM files directly — it requires a PKCS#12 keystore.

```bash
openssl pkcs12 -export \
  -in scu1.crt \
  -inkey scu1.key \
  -name scu1 \
  -out scu1.p12 \
  -passout pass:changeit
```

---

## 5️⃣ Create Client Trust Store

The client needs to trust the CA that signed the server certificate.

```bash
keytool -importcert -noprompt \
  -alias dicom-ca \
  -file shared/pki/ca/ca.crt \
  -keystore shared/pki/clients/dcm1/truststore.p12 \
  -storetype PKCS12 \
  -storepass changeit
```

---

## 6️⃣ Configure IRIS (Server Side)

In the IRIS Management Portal, create a new SSL/TLS Configuration:

| Setting | Value |
|---------|-------|
| Configuration Name | `DICOM-SCU-TLS` |
| Type | Server |
| Client certificate verification | Require |
| Trusted CA certificate(s) | `/shared/pki/ca/ca.crt` |
| Server certificate | `/shared/pki/server/server.crt` |
| Server private key | `/shared/pki/server/server.key` |
| Private key type | RSA |

**Cryptographic Settings:**

| Setting | Value |
|---------|-------|
| Minimum Protocol Version | TLSv1.2 |
| Maximum Protocol Version | TLSv1.3 |
| Cipherlist (TLSv1.2) | `ALL:!aNULL:!eNULL:!EXP:!SSLv2` |
| Ciphersuites (TLSv1.3) | `TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256` |

---

## 7️⃣ Send DICOM with mTLS

Using the standard Use Case 1 example, but with TLS enabled:

```bash
docker exec -it tools bash
```

```bash
./storescu \
  -b DCM_PDF_SCP \
  -c IRIS_PDF_SCU@iris:2010 \
  --tls-protocol TLSv1.2 \
  --tls-cipher TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 \
  --tls-cipher TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 \
  --key-store /shared/pki/clients/dcm1/scu1.p12 \
  --key-store-type PKCS12 \
  --key-store-pass changeit \
  --key-pass changeit \
  --trust-store /shared/pki/clients/dcm1/truststore.p12 \
  --trust-store-type PKCS12 \
  --trust-store-pass changeit \
  /shared/pdf/embeddedpdf.dcm
```

### Debugging TLS Issues

Add this before the command to see detailed TLS handshake logs:

```bash
JAVA_TOOL_OPTIONS="-Djavax.net.debug=ssl,handshake" ./storescu ...
```

---

## 📋 Quick Reference

| Item | Contains |
|------|----------|
| **CA** | Signs all certificates |
| **Server cert** | `server.crt` + `server.key` |
| **Client cert** | `scu1.crt` + `scu1.key` |
| **Client keystore** | `scu1.p12` (cert + key for storescu) |
| **Trust store** | `ca.crt` only (no private keys) |

---

## 🏢 Production Considerations: Intermediate CAs

For production environments, consider using **intermediate CAs** instead of signing certificates directly with the root CA:

```
Root CA (offline, highly secured)
├── Server Intermediate CA
│   └── Server certificates
└── Client Intermediate CA
    └── Client certificates
```

**Benefits:**

- **Security**: Keep the root CA offline and rarely used
- **Revocation**: Revoke an intermediate CA without rebuilding entire PKI
- **Separation**: Different trust domains for clients, servers, departments, etc.
- **Compliance**: Many security standards require this architecture

When using intermediate CAs, certificates must include the full chain:

```bash
cat server.crt server-ca.crt root.crt > server_chain.crt
```

And trust stores need both the intermediate and root CA certificates.

---

## 📚 Learn More

- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [DICOM Security Profiles](https://dicom.nema.org/medical/dicom/current/output/chtml/part15/chapter_B.html)
- [InterSystems TLS Configuration](https://docs.intersystems.com/iris/csp/docbook/DocBook.UI.Page.cls?KEY=GCAS_ssltls)
