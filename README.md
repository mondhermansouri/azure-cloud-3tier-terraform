# Pipeline CI/CD Terraform — Application Web Azure 3 Tiers

Infrastructure-as-Code **modulaire** (Terraform) + pipeline **CI/CD GitHub Actions**
provisionnant l'architecture du schéma `pipeline-Azure.png` :
une application web Azure **3 tiers** (Présentation / Métier / Données),
haute disponibilité sur 2 zones, sécurité, scalabilité, performance et résilience.

> Le schéma d'origine illustre le pipeline avec Azure DevOps (Repos / Pipelines /
> Artifacts). Ici la chaîne **Build → Test → Deploy → Dev/Test/Prod** est
> transposée en **GitHub Actions**, et l'infrastructure est décrite en Terraform.

## Architecture provisionnée

| Bloc du schéma | Module Terraform | Ressources principales |
|---|---|---|
| Edge / Global | `modules/edge` | Front Door (Global Entry), WAF managé OWASP, DNS public |
| Front Tier (réseau) | `modules/networking` | VNet 10.x/16, sous-réseaux public/app/data ×2 zones, NAT Gateway, Bastion, NSG, Private DNS, plan DDoS |
| App Tier (métier) | `modules/compute` | App Service Plan zone-redundant, Web App + API, Autoscale CPU, Application Gateway WAF_v2 |
| Data Tier (données) | `modules/data` | Azure SQL Primaire + Secondaire (Failover Group géo-redondant), Private Endpoint |
| Sécurité & Identité | `modules/security` | Key Vault (RBAC), pare-feu réseau, audit |
| Supervision & Alerting | `modules/monitoring` | Log Analytics, Application Insights, Action Group, alertes métriques |
| Stockage & Contenu | `modules/storage` | Blob (images/documents/uploads), Azure Files, CDN |
| Messagerie & Intégration | `modules/messaging` | Service Bus (queues/topics), Event Grid, Azure Functions |

## Structure du dépôt

```
.
├── main.tf / variables.tf / outputs.tf / locals.tf / providers.tf / versions.tf
├── modules/                 # modules réutilisables (un par domaine)
│   ├── networking/ security/ monitoring/ storage/
│   ├── data/ compute/ edge/ messaging/
├── environments/            # configuration par environnement
│   ├── dev/   (terraform.tfvars + backend.tfvars)
│   ├── test/
│   └── prod/
├── .github/workflows/
│   ├── _terraform.yml       # workflow réutilisable (Build→Test→Deploy)
│   ├── ci.yml               # PR : fmt + validate + tflint + scan + plan
│   ├── cd.yml               # merge main : apply dev → test → prod
│   └── destroy.yml          # destruction manuelle contrôlée
├── scripts/bootstrap-backend.sh
├── .tflint.hcl
└── .gitignore
```

## Le pipeline CI/CD (GitHub Actions)

```
 Pull Request ──► ci.yml ──►  Build (fmt, init, validate)
                              Test  (tflint, Trivy IaC scan)
                              Plan  (dev, test, prod) ──► commentaire sur la PR

 Merge sur main ─► cd.yml ─►  Deploy dev ─► Deploy test ─► Deploy prod
                              (chaque étape gated par un GitHub Environment)
```

- `_terraform.yml` est un **workflow réutilisable** (`workflow_call`) : un seul
  endroit décrit le cycle Terraform, paramétré par `environment` et `action`.
- Les **approbations manuelles** se règlent dans *Settings → Environments*
  (reviewers requis sur `test` et `prod`, règles de protection de branche).
- `concurrency` empêche deux `apply` simultanés sur le même état.

## Mise en route

### 1. Bootstrap du backend distant + Service Principal (une fois)

```bash
az login
LOCATION=francecentral SA_STATE=sttfstateweb3t bash scripts/bootstrap-backend.sh
```

Le script crée le Storage Account d'état et un Service Principal, puis affiche
les valeurs à enregistrer dans **GitHub → Settings → Secrets and variables → Actions** :

| Secret | Description |
|---|---|
| `ARM_CLIENT_ID` | App ID du Service Principal |
| `ARM_CLIENT_SECRET` | Secret du Service Principal |
| `ARM_TENANT_ID` | Tenant Entra ID |
| `ARM_SUBSCRIPTION_ID` | Abonnement Azure cible |

> Adaptez `storage_account_name` dans `environments/*/backend.tfvars` si vous
> changez le nom (contrainte d'unicité globale).

### 2. Créer les Environments GitHub

Dans *Settings → Environments*, créez `dev`, `test`, `prod`.
Ajoutez des **required reviewers** sur `test` et `prod` pour activer les
approbations manuelles avant `apply`.

### 3. Exécution

- Ouvrir une PR → `ci.yml` produit les plans et les commente.
- Merger sur `main` → `cd.yml` déploie dev, puis test, puis prod (avec approbations).
- Détruire un environnement → lancer `destroy.yml` (saisir `DETRUIRE`).

## Tests

Des tests natifs Terraform (`tests/*.tftest.hcl`) s'exécutent en `command = plan`
avec des **providers mockés** : aucune credential Azure, aucune ressource créée.

```bash
terraform init -backend=false
terraform test
```

| Fichier | Couverture |
|---|---|
| `tests/root.tftest.hcl` | Nommage, câblage inter-modules, plan dev + prod calculable |
| `tests/networking.tftest.hcl` | Sous-réseaux, Bastion, 5 zones DNS privées, délégation, count DDoS |
| `tests/data.tftest.hcl` | Failover group + serveur secondaire selon `enable_geo_replication` |
| `tests/validation.tftest.hcl` | Règle de validation de `environment` (échec attendu) |

Ces tests constituent le job `unit-tests` de `ci.yml` et **bloquent** les plans
s'ils échouent. État actuel : **8 passed, 0 failed**.

## Exécution locale (optionnel)

```bash
export ARM_CLIENT_ID=... ARM_CLIENT_SECRET=... ARM_TENANT_ID=... ARM_SUBSCRIPTION_ID=...
terraform init -backend-config="environments/dev/backend.tfvars"
terraform plan  -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

## Différences par environnement

| | dev | test | prod |
|---|---|---|---|
| App Service SKU | B1 | P1v3 | P2v3 |
| Autoscale max | 2 | 4 | 10 |
| SQL | serverless | GP_Gen5_2 | BC_Gen5_4 |
| Géo-réplication | non | non | **oui** |
| DDoS Standard | non | non | **oui** |
| Front Door | Standard | Standard | **Premium** |

## Notes & points d'attention

- **TLS Application Gateway** : le listener est en HTTP (TLS terminé en amont par
  Front Door). Pour une exposition directe, ajoutez un certificat et un listener HTTPS.
- **Propagation RBAC** : l'écriture des secrets SQL dans Key Vault dépend d'une
  attribution de rôle ; en cas d'erreur transitoire au premier `apply`, relancer.
- **Plan DDoS** et **Front Door Premium** sont coûteux : activés uniquement en prod.
- Les `*.tfvars` d'environnement sont versionnés (configuration, **pas de secrets**) ;
  les secrets transitent uniquement par les secrets GitHub / Key Vault.
