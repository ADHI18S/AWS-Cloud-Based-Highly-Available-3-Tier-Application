# 🔐 AWS Certificate Manager (ACM) Setup

## Overview

AWS Certificate Manager allows you to provision SSL/TLS certificates for use with AWS services such as ALB, CloudFront, and API Gateway.

---

## Requesting a Certificate

1. Navigate to Certificate Manager in AWS Console.
2. Choose to request a public certificate.
3. Enter your domain name (e.g., domain.digitalplat.org).
4. Choose DNS validation.
5. Add CNAME records to your DNS provider as prompted.
6. Wait for certificate to be issued (status = Issued).

---

## Using Certificate with ALB

- Attach the ACM certificate to your Application Load Balancer HTTPS listener.
- Configure HTTP listener to redirect to HTTPS.
- Certificates are auto-renewed by AWS, no manual renewal needed.

---

_Last updated: October 2025_
