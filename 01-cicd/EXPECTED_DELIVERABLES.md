# CI/CD Expected Deliverables 

## 1. Secure GitHub Actions workflow files
- Check at [ci-cd.yaml](../.github/workflows/ci-cd.yaml)

## 2. Documentation on security measures implemented
- Actions pinned to commit SHAs.
- AWS auth uses OIDC. No static keys.
- Unit tests run on each push and PR.
- SAST: Bandit.
- Dependency scan: Safety.
- Secrets scan: Gitleaks.
- IaC scan: Checkov.
- Container scan: Trivy. Fail on HIGH and CRITICAL.
- Kubernetes manifests validated (server-side dry run).
- Production deploy requires environment approval.
- Rollout health checked. Roll back on failure.
- DAST: OWASP ZAP baseline. Report uploaded.
- Compliance check runs. Report uploaded.
- Images use SHA tags only. No latest.

## 3. Evidence of successful pipeline execution with security scanning
- Check at GitHub action of this repository (Cannot run some steps in Workflow due to server, environment and secret configuration).

## 4. Explanation of remediation for identified security issues
- Bandit: Remove unsafe calls. Use safe APIs. Re-scan.
- Safety: Upgrade or pin safe versions. Rebuild. Re-scan.
- Gitleaks: Rotate keys. Remove secrets from git. Use a vault. Re-scan.
- Checkov: Close public access. Add encryption. Least privilege. Re-scan.
- Trivy: Bump base image. Apply patches. Rebuild. Re-scan.
- ZAP: Fix input validation. Add security headers. Re-test.
- Compliance: Apply required controls. Keep evidence. Re-run check.
