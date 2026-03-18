set shell := ["bash", "-euo", "pipefail", "-c"]

aws_region := env_var_or_default("AWS_REGION", "ap-southeast-3")
github_repository := env_var_or_default("GITHUB_REPOSITORY", "salman-frs/paved-road-aws")
base_domain := env_var_or_default("BASE_DOMAIN", "salmanfrs.dev")
cloudflare_zone_id := env_var_or_default("CLOUDFLARE_ZONE_ID", "")

default:
    @just --list

bootstrap-admin-init:
    terraform -chdir=platform/bootstrap/admin/terraform init -backend=false

bootstrap-admin-apply:
    terraform -chdir=platform/bootstrap/admin/terraform apply \
      -var "aws_region={{ aws_region }}" \
      -var "github_repository={{ github_repository }}"

bootstrap-cluster-init:
    bucket="$(terraform -chdir=platform/bootstrap/admin/terraform output -raw terraform_state_bucket)"; \
    table="$(terraform -chdir=platform/bootstrap/admin/terraform output -raw terraform_lock_table)"; \
    terraform -chdir=platform/bootstrap/cluster/terraform init \
      -backend-config="bucket=$bucket" \
      -backend-config="dynamodb_table=$table" \
      -backend-config="key=bootstrap/cluster/terraform.tfstate" \
      -backend-config="region={{ aws_region }}"

bootstrap-cluster-apply:
    terraform -chdir=platform/bootstrap/cluster/terraform apply \
      -var "aws_region={{ aws_region }}" \
      -var "base_domain={{ base_domain }}"

bootstrap-kubeconfig:
    cluster_name="$(terraform -chdir=platform/bootstrap/cluster/terraform output -raw cluster_name)"; \
    aws eks update-kubeconfig --name "$cluster_name" --region {{ aws_region }}

bootstrap-argocd:
    helm repo add argo https://argoproj.github.io/argo-helm
    helm upgrade --install argocd argo/argo-cd \
      --version 9.4.12 \
      --namespace argocd \
      --create-namespace \
      -f platform/bootstrap/argocd/values.yaml \
      --wait \
      --timeout 15m
    kubectl apply -f platform/bootstrap/argocd/project.yaml
    kubectl apply -f platform/bootstrap/argocd/root-application.yaml

bootstrap-dns:
    if [ -z "{{ cloudflare_zone_id }}" ]; then \
      echo "Set CLOUDFLARE_ZONE_ID before running bootstrap-dns" >&2; \
      exit 1; \
    fi; \
    hostname="$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"; \
    if [ -z "$hostname" ]; then \
      echo "Ingress load balancer hostname is not ready yet" >&2; \
      exit 1; \
    fi; \
    terraform -chdir=platform/bootstrap/cluster/terraform apply \
      -var "aws_region={{ aws_region }}" \
      -var "base_domain={{ base_domain }}" \
      -var "cloudflare_zone_id={{ cloudflare_zone_id }}" \
      -var "ingress_public_hostname=$hostname"

bootstrap-demo-service:
    kubectl apply -f gitops/dev/orders-api/application.yaml

bootstrap-all:
    just bootstrap-admin-init
    just bootstrap-admin-apply
    just bootstrap-cluster-init
    just bootstrap-cluster-apply
    just bootstrap-kubeconfig
    just bootstrap-argocd
    just bootstrap-dns

destroy-platform:
    kubectl delete -f platform/bootstrap/argocd/root-application.yaml --ignore-not-found=true
    for attempt in {1..45}; do \
      app_count="$(kubectl get applications.argoproj.io -n argocd --no-headers 2>/dev/null | wc -l | tr -d ' ')"; \
      if [ "$app_count" = "0" ]; then \
        break; \
      fi; \
      sleep 10; \
    done; \
    app_count="$(kubectl get applications.argoproj.io -n argocd --no-headers 2>/dev/null | wc -l | tr -d ' ' || echo 0)"; \
    if [ "$app_count" != "0" ]; then \
      echo "Timed out waiting for Argo applications to be pruned" >&2; \
      exit 1; \
    fi; \
    helm uninstall argocd -n argocd || true; \
    vpc_id="$(terraform -chdir=platform/bootstrap/cluster/terraform output -raw vpc_id)"; \
    for attempt in {1..45}; do \
      clb_count="$(aws elb describe-load-balancers --region {{ aws_region }} --query \"length(LoadBalancerDescriptions[?VPCId==\`$vpc_id\`])\" --output text 2>/dev/null || echo 0)"; \
      alb_count="$(aws elbv2 describe-load-balancers --region {{ aws_region }} --query \"length(LoadBalancers[?VpcId==\`$vpc_id\`])\" --output text 2>/dev/null || echo 0)"; \
      requester_managed_eni_count="$(aws ec2 describe-network-interfaces --region {{ aws_region }} --filters Name=vpc-id,Values=$vpc_id Name=requester-managed,Values=true --query 'length(NetworkInterfaces)' --output text 2>/dev/null || echo 0)"; \
      extra_sg_count="$(aws ec2 describe-security-groups --region {{ aws_region }} --filters Name=vpc-id,Values=$vpc_id --query \"length(SecurityGroups[?GroupName!=\`default\`])\" --output text 2>/dev/null || echo 0)"; \
      if [ "$clb_count" = "0" ] && [ "$alb_count" = "0" ] && [ "$requester_managed_eni_count" = "0" ] && [ "$extra_sg_count" = "0" ]; then \
        exit 0; \
      fi; \
      sleep 20; \
    done; \
    echo "Timed out waiting for Kubernetes load balancers to be removed" >&2; \
    exit 1

destroy-cluster:
    zone_args=(); \
    if [ -n "{{ cloudflare_zone_id }}" ]; then zone_args+=(-var "cloudflare_zone_id={{ cloudflare_zone_id }}"); fi; \
    terraform -chdir=platform/bootstrap/cluster/terraform destroy \
      -var "aws_region={{ aws_region }}" \
      -var "base_domain={{ base_domain }}" \
      "${zone_args[@]}"

destroy:
    just destroy-platform
    just destroy-cluster

nuke:
    just destroy
    terraform -chdir=platform/bootstrap/admin/terraform destroy \
      -var "aws_region={{ aws_region }}" \
      -var "github_repository={{ github_repository }}"
