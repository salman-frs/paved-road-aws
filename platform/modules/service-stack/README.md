# Service Stack Module

`platform/modules/service-stack/` owns service-level AWS resources only:

- per-service ECR repository
- IRSA role and least-privilege access for the chosen backing dependency
- optional Cloudflare DNS record for the service hostname
- optional demo backing dependency: S3 bucket or SQS queue
- standardized secret path contract

It must not own VPCs, EKS, shared observability backends, or ArgoCD installation.
