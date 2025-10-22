# Azure Deployment Guide - Spring PetClinic

**Emergency Migration from AWS to Azure - Fast-Track Deployment**

## 🚨 Quick Start (Emergency Path)

If you're in an active outage, follow this condensed guide for fastest deployment.

### Prerequisites Check (5 minutes)

```bash
# 1. Verify Azure CLI
az --version
az login
az account show

# 2. Verify Terraform
terraform --version

# 3. Verify Docker
docker --version

# 4. Verify application JAR exists
ls -la petclinic/target/*.jar

# If JAR doesn't exist:
cd petclinic && mvn clean package -DskipTests && cd ..
```

### Step 1: Build and Push Docker Image (10 minutes)

```bash
# Build Docker image
cd petclinic
docker build -t petclinic:azure .

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u ViniciusSouza --password-stdin

# Tag and push
docker tag petclinic:azure ghcr.io/viniciusouza/petclinic:latest
docker tag petclinic:azure ghcr.io/viniciusouza/petclinic:2.7.18
docker push ghcr.io/viniciusouza/petclinic:latest
docker push ghcr.io/viniciusouza/petclinic:2.7.18

cd ..
```

### Step 2: Deploy Azure Infrastructure (15 minutes)

```bash
cd azure/terraform

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars

# IMPORTANT: Edit terraform.tfvars
# Update these values for uniqueness:
# - db_server_name = "petclinic-mysql-prod-YOUR-UNIQUE-ID"
# - app_service_name = "petclinic-prod-YOUR-UNIQUE-ID"

# Set database password
export TF_VAR_db_admin_password="YourSecurePassword123!"

# Initialize and deploy
terraform init
terraform plan
terraform apply -auto-approve

# Save outputs
terraform output > deployment-info.txt
cat deployment-info.txt
```

### Step 3: Deploy Database Schema (5 minutes)

```bash
# Get database connection info
DB_HOST=$(terraform output -raw database_fqdn)

# Deploy schema
cd ../../petclinic
mysql -h $DB_HOST -u adminuser -p petclinic < src/main/resources/db/mysql/schema.sql
mysql -h $DB_HOST -u adminuser -p petclinic < src/main/resources/db/mysql/data.sql

# Verify data
mysql -h $DB_HOST -u adminuser -p petclinic -e "SELECT COUNT(*) FROM vets;"
```

### Step 4: Verify Deployment (5 minutes)

```bash
# Get application URL
APP_URL=$(terraform output -raw app_service_url)

# Check health
curl $APP_URL/actuator/health

# Open in browser
open $APP_URL

# Test features:
# ✓ View veterinarians
# ✓ Find owners
# ✓ Create owner
# ✓ Add pet
# ✓ Schedule visit
```

### Step 5: DNS Cutover (10 minutes)

```bash
# Get the App Service default hostname
echo "Point your DNS to: $(terraform output -raw app_service_url)"

# Update your DNS CNAME record:
# Type: CNAME
# Name: petclinic (or www, or @)
# Value: petclinic-prod-<unique-id>.azurewebsites.net
# TTL: 300 (5 minutes for quick cutover)

# Wait for DNS propagation
# Check with: dig petclinic.yourdomain.com
```

**Total Time: ~50 minutes** ⏱️

---

## 📋 Detailed Deployment Guide

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Cloud                              │
│                                                              │
│  ┌──────────────────┐         ┌──────────────────────────┐ │
│  │                  │         │  Azure Database for MySQL │ │
│  │  Azure App       │────────▶│  Flexible Server          │ │
│  │  Service         │         │  - MySQL 8.0              │ │
│  │  (Linux          │         │  - 32 GB Storage          │ │
│  │   Container)     │         │  - Burstable SKU          │ │
│  │                  │         └──────────────────────────┘ │
│  └──────────────────┘                                       │
│         │                                                    │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────────┐                                       │
│  │  Application     │                                       │
│  │  Insights        │                                       │
│  │  (Monitoring)    │                                       │
│  └──────────────────┘                                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
         ▲
         │
    Internet Users
```

### Environment Configuration

#### Development/Testing
```hcl
# azure/terraform/terraform.tfvars
app_service_sku = "B1"              # ~$13/month
db_sku_name     = "B_Standard_B1ms"  # ~$20/month
Total: ~$38/month
```

#### Production
```hcl
# azure/terraform/terraform.tfvars
app_service_sku = "P1v2"                    # ~$96/month
db_sku_name     = "GP_Standard_D2ds_v4"     # ~$140/month
Total: ~$256/month
```

### Database Migration Options

#### Option A: Fresh Start (Fastest)
```bash
# Use schema and data from repository
mysql -h $DB_HOST -u adminuser -p petclinic < src/main/resources/db/mysql/schema.sql
mysql -h $DB_HOST -u adminuser -p petclinic < src/main/resources/db/mysql/data.sql
```

#### Option B: Migrate from AWS RDS
```bash
# 1. Export from AWS RDS
mysqldump -h <aws-rds-endpoint>.rds.amazonaws.com \
  -u admin -p petclinic > aws_backup.sql

# 2. Import to Azure
mysql -h $DB_HOST -u adminuser -p petclinic < aws_backup.sql

# 3. Verify row counts match
mysql -h <aws-endpoint> -u admin -p petclinic -e "SELECT COUNT(*) FROM vets;"
mysql -h $DB_HOST -u adminuser -p petclinic -e "SELECT COUNT(*) FROM vets;"
```

### Application Configuration

The Terraform configuration automatically sets these environment variables:

```bash
SPRING_PROFILES_ACTIVE=mysql
MYSQL_URL=jdbc:mysql://<server>.mysql.database.azure.com/petclinic
MYSQL_USER=adminuser
MYSQL_PASS=<password>
WEBSITES_PORT=80
APPLICATIONINSIGHTS_CONNECTION_STRING=<connection-string>
```

No code changes required! ✅

### Monitoring Setup

#### Application Insights

```bash
# View in Azure Portal
az monitor app-insights component show \
  --app petclinic-insights-prod \
  --resource-group rg-petclinic-prod

# Open Live Metrics
open "https://portal.azure.com/#@<tenant>/resource/subscriptions/<sub>/resourceGroups/rg-petclinic-prod/providers/microsoft.insights/components/petclinic-insights-prod/overview"
```

#### Alerts Configured

1. **App Down** - Severity 0 (Critical)
   - Triggers when health check fails
   - Checks every 1 minute

2. **High Response Time** - Severity 2 (Warning)
   - Triggers when average response > 5 seconds
   - Checks every 5 minutes

3. **High Error Rate** - Severity 1 (Error)
   - Triggers when HTTP 5xx > 10 requests/5min
   - Checks every 1 minute

### Performance Tuning

#### Scale Up (Vertical Scaling)
```bash
# Upgrade App Service Plan
az appservice plan update \
  --resource-group rg-petclinic-prod \
  --name plan-petclinic-prod \
  --sku P2v2
```

#### Scale Out (Horizontal Scaling)
```bash
# Add more instances
az appservice plan update \
  --resource-group rg-petclinic-prod \
  --name plan-petclinic-prod \
  --number-of-workers 3
```

#### Auto-Scaling (Future Enhancement)
```bash
# Enable auto-scale
az monitor autoscale create \
  --resource-group rg-petclinic-prod \
  --resource plan-petclinic-prod \
  --resource-type Microsoft.Web/serverfarms \
  --name autoscale-petclinic \
  --min-count 1 \
  --max-count 5 \
  --count 1

# Add CPU-based rule
az monitor autoscale rule create \
  --resource-group rg-petclinic-prod \
  --autoscale-name autoscale-petclinic \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1
```

### Security Hardening (Post-Migration)

#### 1. Restrict Database Access
```hcl
# azure/terraform/variables.tf
allowed_ip_addresses = [
  "YOUR-OFFICE-IP/32",
  "YOUR-HOME-IP/32"
]
```

#### 2. Enable Database SSL
```hcl
# azure/terraform/database.tf
resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  value = "ON"
}
```

Update connection string:
```
jdbc:mysql://<server>.mysql.database.azure.com/petclinic?useSSL=true&requireSSL=true
```

#### 3. Use Azure Key Vault for Secrets
```bash
# Create Key Vault
az keyvault create \
  --name kv-petclinic-prod \
  --resource-group rg-petclinic-prod \
  --location eastus

# Store database password
az keyvault secret set \
  --vault-name kv-petclinic-prod \
  --name db-password \
  --value "YourSecurePassword123!"

# Configure App Service to use Key Vault
az webapp config appsettings set \
  --resource-group rg-petclinic-prod \
  --name petclinic-prod-<id> \
  --settings MYSQL_PASS="@Microsoft.KeyVault(SecretUri=https://kv-petclinic-prod.vault.azure.net/secrets/db-password/)"
```

#### 4. Enable VNet Integration
```hcl
# azure/terraform/variables.tf
enable_vnet_integration = true
```

### Troubleshooting

#### Application Won't Start

```bash
# Check logs
az webapp log tail \
  --resource-group rg-petclinic-prod \
  --name petclinic-prod-<id>

# Common issues:
# 1. Database connection failed
#    → Check firewall rules
#    → Verify credentials

# 2. Port mismatch
#    → Verify WEBSITES_PORT=80 in app settings

# 3. Image pull failed
#    → Check ghcr.io authentication
#    → Verify image exists
```

#### Database Connection Errors

```bash
# Test from App Service container
az webapp ssh --resource-group rg-petclinic-prod --name petclinic-prod-<id>

# Inside container:
mysql -h <db-host>.mysql.database.azure.com -u adminuser -p

# If connection fails:
# 1. Check firewall rules allow Azure services
# 2. Verify password in app settings
# 3. Check database server is running
```

#### Slow Performance

```bash
# Check Application Insights
# Look for:
# - Slow database queries
# - High CPU/memory usage
# - Network latency

# Quick fixes:
# 1. Scale up App Service Plan
# 2. Add database read replicas
# 3. Enable CDN for static content
```

### Cost Management

#### View Current Costs
```bash
# Cost analysis
az consumption usage list \
  --start-date 2025-10-01 \
  --end-date 2025-10-22 \
  --query "[].{Date:usageStart, Cost:pretaxCost, Service:instanceName}" \
  --output table
```

#### Set Cost Alerts
```bash
# Create budget
az consumption budget create \
  --amount 300 \
  --category cost \
  --name petclinic-monthly-budget \
  --time-period start-date=2025-10-01 \
  --time-grain monthly
```

### Rollback Procedures

#### Rollback to Previous Docker Image
```bash
# Deploy previous version
az webapp config container set \
  --resource-group rg-petclinic-prod \
  --name petclinic-prod-<id> \
  --docker-custom-image-name ghcr.io/viniciusouza/petclinic:2.7.18

# Restart
az webapp restart \
  --resource-group rg-petclinic-prod \
  --name petclinic-prod-<id>
```

#### Rollback DNS (Back to AWS)
```bash
# Update DNS CNAME to point back to AWS
# Type: CNAME
# Name: petclinic
# Value: <aws-app-runner-url>.awsapprunner.com
```

#### Full Infrastructure Rollback
```bash
# Destroy Azure resources
cd azure/terraform
terraform destroy -auto-approve

# Costs stop immediately
```

### Maintenance

#### Update Application
```bash
# 1. Build new image
cd petclinic
mvn clean package
docker build -t petclinic:azure .

# 2. Push to registry
docker tag petclinic:azure ghcr.io/viniciusouza/petclinic:latest
docker push ghcr.io/viniciusouza/petclinic:latest

# 3. Restart App Service (pulls new image)
az webapp restart \
  --resource-group rg-petclinic-prod \
  --name petclinic-prod-<id>
```

#### Database Maintenance
```bash
# View backup retention
az mysql flexible-server backup show \
  --resource-group rg-petclinic-prod \
  --server-name petclinic-mysql-prod

# Manual backup
mysqldump -h $DB_HOST -u adminuser -p petclinic > backup_$(date +%Y%m%d).sql

# Restore from backup
mysql -h $DB_HOST -u adminuser -p petclinic < backup_20251022.sql
```

## 📚 Additional Resources

- [Implementation Plan](../plans/plan-emergency-azure-migration.md)
- [Azure Terraform Files](../azure/terraform/)
- [Terraform README](../azure/README.md)
- [Azure App Service Docs](https://learn.microsoft.com/en-us/azure/app-service/)
- [Azure Database for MySQL Docs](https://learn.microsoft.com/en-us/azure/mysql/)

## 🆘 Emergency Contacts

If you encounter critical issues:
1. Check Application Insights for errors
2. Review App Service logs
3. Verify database connectivity
4. Contact Azure Support if infrastructure issues

## ✅ Post-Deployment Checklist

- [ ] Application accessible at Azure URL
- [ ] Health endpoint returns `UP`
- [ ] Database contains expected data
- [ ] All features working (vets, owners, pets, visits)
- [ ] Application Insights receiving telemetry
- [ ] Alerts configured and tested
- [ ] DNS updated (if applicable)
- [ ] AWS infrastructure kept as fallback (initially)
- [ ] Team notified of new URL
- [ ] Documentation updated

## 🔜 Next Steps

After emergency deployment is stable:
1. Set up GitHub Actions CI/CD (automated)
2. Implement Azure Key Vault for secrets
3. Enable VNet integration
4. Configure auto-scaling
5. Set up Azure Front Door (CDN)
6. Enable advanced monitoring dashboards
7. Decommission AWS infrastructure
