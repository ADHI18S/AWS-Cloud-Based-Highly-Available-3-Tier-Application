# 🔒 Security

## Transport Layer
- HTTPS enforced with HTTP redirect
- TLS 1.2+ with ACM certificate
- Security headers (X-Frame-Options, X-XSS-Protection)

## Application Layer
- Parameterized queries to prevent SQL injection
- Input validation on client and server
- No secrets committed; config.py ignored
- Authentication for results access

## Infrastructure
- EC2 accepts traffic only from ALB
- SSH restricted to admin IPs
- Database in private subnet with no public access
- Regular system and package updates

## Reporting Issues

Please report security vulnerabilities to: santhoshrajv10@gmail.com

---

## Best Practices

- Change all default passwords
- Schedule database backups
- Audit logs with AWS CloudTrail
- Keep dependencies up to date
