# Terraform CI/CD Pipeline — Azure 3-Tier Web Architecture

Modular Infrastructure as Code (**Terraform**) with an automated **GitHub Actions CI/CD pipeline** provisioning the architecture illustrated in [`pipeline-Azure.png`](pipeline-Azure.png): a highly available, secure, scalable, and resilient **3-Tier Azure Web Application** (Presentation / Business Logic / Data) distributed across 2 availability zones.

> **Architecture Context:** While traditional reference architectures often feature Azure DevOps (Repos / Pipelines / Artifacts), this implementation transposes the entire **Build → Test → Plan → Deploy → Multi-Environment** lifecycle into **GitHub Actions** with infrastructure declared natively in modular Terraform.

---

## 1. Provisioned Architecture

| Architectural Layer | Terraform Module | Primary Managed Resources |
|---|---|---|
| **Edge & Global Routing** | `modules/edge` | Azure Front Door (Global Entry), Managed OWASP WAF Policies, Public DNS |
| **Front Tier (Networking)** | `modules/networking` | VNet `10.x/16`, Public/App/Data subnets across 2 AZs, NAT Gateway, Azure Bastion, NSGs, Private DNS Zones, DDoS Protection Plan |
| **App Tier (Compute)** | `modules/compute` | Zone-Redundant App Service Plan, Web App + REST API, CPU-based Autoscale, Application Gateway WAF_v2 |
| **Data Tier (Persistence)** | `modules/data` | Azure SQL Primary + Secondary (Geo-Redundant Failover Group), Private Endpoints |
| **Security & Identity** | `modules/security` | Azure Key Vault (Azure RBAC), Network Firewalls, Audit Logging |
| **Observability & Alerting** | `modules/monitoring` | Log Analytics Workspace, Application Insights, Action Groups, Metric Alert Rules |
| **Storage & Content** | `modules/storage` | Azure Blob Storage (images/documents/uploads), Azure Files, CDN integration |
| **Messaging & Integration** | `modules/messaging` | Azure Service Bus (Queues/Topics), Event Grid, Azure Functions |

---

## 2. Repository Structure

```
.
├── main.tf / variables.tf / outputs.tf / locals.tf / providers.tf / versions.tf
├── modules/                 # Domain-isolated reusable modules
│   ├── networking/ security/ monitoring/ storage/
│   ├── data/ compute/ edge/ messaging/
├── environments/            # Multi-environment parameters and state configs
│   ├── dev/   (terraform.tfvars + backend.tfvars)
│   ├── test/
│   └── prod/
├── tests/                   # Native Terraform unit tests (mocked providers)
│   ├── root.tftest.hcl
│   ├── networking.tftest.hcl
│   ├── data.tftest.hcl
│   └── validation.tftest.hcl
├── .github/workflows/
│   ├── _terraform.yml       # Reusable workflow (Build → Test → Plan → Deploy)
│   ├── ci.yml               # PR & Push: fmt + validate + tflint + trivy + unit tests + plan
│   ├── cd.yml               # Main branch: cascading deploy dev → test → prod
│   └── destroy.yml          # Controlled manual teardown (workflow_dispatch)
├── scripts/bootstrap-backend.sh
├── .tflint.hcl
└── .gitignore
```

---

## 3. CI/CD Pipeline Architecture (GitHub Actions)

```
 Pull Request / Push ──► ci.yml ──► Build (fmt, init, validate)
                                   Test  (tflint, Trivy IaC scan, mocked terraform test)
                                   Plan  (dev, test, prod) ──► PR Comment / Summary

 Merge to main       ──► cd.yml ──► Deploy dev ─► Deploy test ─► Deploy prod
                                   (Each stage protected by GitHub Environment gates)
```

- **Reusable Workflow (`_terraform.yml`):** A centralized `workflow_call` workflow standardizes the Terraform lifecycle parameterized by `environment` and `action` (`plan`, `apply`, `destroy`).
- **Secret & Credential Guards:** Workflows gracefully detect whether live Azure Service Principal credentials are configured in repository secrets. When absent, the pipeline executes syntax checks, linting, and mocked unit tests offline without failing or creating cloud resources.
- **Manual Approvals:** Configurable via GitHub repository settings (*Settings → Environments*) to require designated reviewers on `test` and `prod` before `apply`.
- **State Concurrency Control:** Workflow concurrency locks prevent simultaneous runs against the same environment state.

---

## 4. Getting Started

### Step A — Backend Bootstrap & Service Principal (One-Time Setup)

```bash
az login
LOCATION=francecentral SA_STATE=sttfstateweb3t bash scripts/bootstrap-backend.sh
```

The script provisions the state Storage Account and an Azure Service Principal, displaying the output values to configure in **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `ARM_CLIENT_ID` | Application (Client) ID of the Service Principal |
| `ARM_CLIENT_SECRET` | Client Secret password of the Service Principal |
| `ARM_TENANT_ID` | Microsoft Entra (Azure AD) Tenant ID |
| `ARM_SUBSCRIPTION_ID` | Target Azure Subscription ID |

> *Note:* Adjust `storage_account_name` in `environments/*/backend.tfvars` to match your globally unique state storage name.

### Step B — Configure GitHub Environments

In **Settings → Environments**, create `dev`, `test`, and `prod`. Add required reviewers to `test` and `prod` to enforce manual approvals prior to live cloud deployment.

### Step C — Automated Execution

- **Pull Request or Push to `main`:** `ci.yml` runs formatting checks, linting, static vulnerability analysis, and mocked unit tests.
- **Merge to `main`:** `cd.yml` triggers the staged promotion pipeline across environments (gated by secret presence and environment approvals).
- **Environment Teardown:** Trigger `destroy.yml` manually via `workflow_dispatch` (requires typing `DETRUIRE` to confirm).

---

## 5. Automated Testing & Validation

The project includes native Terraform unit tests ([`tests/*.tftest.hcl`](tests/)) running in `command = plan` mode using **mocked providers**. This ensures 100% offline test execution without requiring Azure credentials or creating live cloud resources:

```bash
terraform init -backend=false
terraform test
```

| Test Suite File | Coverage Scope |
|---|---|
| `tests/root.tftest.hcl` | Resource naming conventions, cross-module wiring, plan evaluation for dev and prod |
| `tests/networking.tftest.hcl` | Subnets, Bastion host, 5 Private DNS Zones, subnet delegations, DDoS count toggles |
| `tests/data.tftest.hcl` | Failover group & secondary replica activation based on `enable_geo_replication` |
| `tests/validation.tftest.hcl` | Input validation rules for environment names (asserting expected failures) |

These tests form the mandatory `unit-tests` gate in `ci.yml`.

---

## 6. Optional Local Execution (Direct Azure Connection)

```bash
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"

terraform init -backend-config="environments/dev/backend.tfvars"
terraform plan  -var-file="environments/dev/terraform.tfvars"
# Billable operation:
# terraform apply -var-file="environments/dev/terraform.tfvars"
```

---

## 7. Environment Comparison Matrix

| Parameter | Dev | Test | Prod |
|---|---|---|---|
| **App Service SKU** | B1 (Basic) | P1v3 (Premium) | P2v3 (Premium) |
| **Autoscale Max Instances** | 2 | 4 | 10 |
| **Azure SQL Tier** | Serverless GP | Provisioned GP_Gen5_2 | Business Critical BC_Gen5_4 |
| **Geo-Replication** | Disabled | Disabled | **Enabled** |
| **DDoS Protection Plan** | Disabled | Disabled | **Enabled** |
| **Front Door SKU** | Standard | Standard | **Premium** (Managed WAF) |

---

## 8. Security & Architectural Considerations

- **TLS Termination:** Application Gateway listener is configured for HTTP because TLS is terminated at the edge by Azure Front Door. For direct public ingress, attach an SSL certificate and configure an HTTPS listener.
- **RBAC Role Propagation:** Key Vault secret writes depend on Azure RBAC role assignments. In rare instances on first apply, allow a brief delay for Azure Entra ID RBAC replication.
- **Cost Awareness:** Dedicated DDoS Protection Plans and Front Door Premium are high-cost resources; they are selectively enabled only in the `prod` environment.
- **Zero Secrets in Repository:** Environment `*.tfvars` contain non-sensitive configuration parameters only. All secrets transit exclusively through Azure Key Vault and GitHub encrypted secrets.
- **Billing Disclaimer:** This project is provided for architectural review, local validation, and automated CI demonstration. Applying it to an active Azure subscription will incur Microsoft Azure cloud charges.
