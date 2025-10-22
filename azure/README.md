# Azure Infrastructure - Spring PetClinic

Terraform configuration for deploying Spring PetClinic to Azure.

## 🚨 Emergency Fast-Track Deployment

This infrastructure supports emergency migration from AWS to Azure.

## Architecture

- **Compute:** Azure App Service (Linux, Container)
- **Database:** Azure Database for MySQL Flexible Server
- **Container Registry:** GitHub Container Registry (ghcr.io)
- **Monitoring:** Azure Application Insights
- **Logging:** Azure Log Analytics

## Prerequisites

1. **Azure CLI** installed and configured
   ```bash
   az --version
   az login
   az account set --subscription "<subscription-id>"
   ```

2. **Terraform** >= 1.5.0
   ```bash
   terraform --version
   ```

3. **Docker image** pushed to GitHub Container Registry
   ```bash
   docker build -t petclinic:latest ../petclinic/
   echo $GITHUB_TOKEN | docker login ghcr.io -u ViniciusSouza --password-stdin
   docker tag petclinic:latest ghcr.io/viniciusouza/petclinic:latest
   docker push ghcr.io/viniciusouza/petclinic:latest
   ```

## Quick Start

### 1. Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# IMPORTANT: Update these for uniqueness
# - db_server_name (must be globally unique)
# - app_service_name (must be globally unique)
```

### 2. Set Database Password

```bash
# Option 1: Environment variable
export TF_VAR_db_admin_password="YourSecurePassword123!"

# Option 2: Will be prompted during apply
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy (takes ~10-15 minutes)
terraform apply

# Note the outputs, especially app_service_url
```

### 4. Deploy Database Schema

```bash
# Get database connection details from outputs
DB_HOST=$(terraform output -raw database_fqdn)
DB_USER=$(terraform output -raw database_name)

# Deploy schema and initial data
cd ../../petclinic
mysql -h $DB_HOST -u adminuser -p petclinic < src/main/resources/db/mysql/schema.sql
mysql -h $DB_HOST -u adminuser -p petclinic < src/main/resources/db/mysql/data.sql
```

### 5. Verify Deployment

```bash
# Get application URL
APP_URL=$(terraform output -raw app_service_url)

# Test health endpoint
curl $APP_URL/actuator/health

# Open in browser
open $APP_URL
```

## Configuration

### Cost Optimization

**Development/Testing (~$38/month):**
```hcl
app_service_sku = "B1"
db_sku_name     = "B_Standard_B1ms"
```

**Production (~$256/month):**
```hcl
app_service_sku = "P1v2"
db_sku_name     = "GP_Standard_D2ds_v4"
```

### Environment Variables

App Service application settings (automatically configured):
- `MYSQL_URL` - Database connection string
- `MYSQL_USER` - Database username
- `MYSQL_PASS` - Database password
- `SPRING_PROFILES_ACTIVE` - Spring profile (mysql)
- `WEBSITES_PORT` - Container port
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Monitoring

## Management Commands

### View Application Logs

```bash
RG_NAME=$(terraform output -raw resource_group_name)
APP_NAME=$(terraform output -raw app_service_name)

# Tail logs
az webapp log tail --resource-group $RG_NAME --name $APP_NAME

# Download logs
az webapp log download --resource-group $RG_NAME --name $APP_NAME
```

### Restart Application

```bash
az webapp restart --resource-group $RG_NAME --name $APP_NAME
```

### Update Container Image

```bash
# After pushing new image to ghcr.io
az webapp config container set \
  --resource-group $RG_NAME \
  --name $APP_NAME \
  --docker-custom-image-name ghcr.io/viniciusouza/petclinic:latest

# Restart to pull new image
az webapp restart --resource-group $RG_NAME --name $APP_NAME
```

### Scale Application

```bash
# Scale App Service Plan
az appservice plan update \
  --resource-group $RG_NAME \
  --name plan-petclinic-prod \
  --sku P2v2

# Scale out (more instances)
az appservice plan update \
  --resource-group $RG_NAME \
  --name plan-petclinic-prod \
  --number-of-workers 2
```

## Monitoring

### Application Insights

```bash
# Open in Azure Portal
az monitor app-insights component show \
  --app petclinic-insights-prod \
  --resource-group $RG_NAME \
  --query "appId" -o tsv

# View live metrics
# https://portal.azure.com -> Application Insights -> Live Metrics
```

### Alerts

Three alerts are configured:
1. **App Down** - Triggers when health check fails
2. **High Response Time** - Triggers when average response > 5s
3. **High Error Rate** - Triggers when HTTP 5xx > 10 requests/5min

## Database Management

### Connect to Database

```bash
DB_HOST=$(terraform output -raw database_fqdn)

# Using MySQL client
mysql -h $DB_HOST -u adminuser -p petclinic

# Using MySQL Workbench
# Host: <db-host>.mysql.database.azure.com
# Port: 3306
# Username: adminuser
# Database: petclinic
```

### Backup Database

```bash
# Manual backup
mysqldump -h $DB_HOST -u adminuser -p petclinic > backup_$(date +%Y%m%d).sql

# Automated backups are configured (7 day retention)
# View backups in Azure Portal
```

### Restore Database

```bash
# From backup file
mysql -h $DB_HOST -u adminuser -p petclinic < backup_20251022.sql
```

## Security

### Current Configuration (Fast-Track)

- ⚠️ Database allows public access (restricted by firewall rules)
- ⚠️ SSL not required for database connections
- ⚠️ Secrets in environment variables (not Key Vault)

### Production Hardening (Post-Migration)

1. **Enable VNet Integration**
   ```hcl
   enable_vnet_integration = true
   ```

2. **Use Azure Key Vault** for secrets
3. **Enable database SSL requirement**
4. **Restrict firewall to specific IPs**
5. **Enable Azure AD authentication**

## Troubleshooting

### Application Won't Start

```bash
# Check logs
az webapp log tail --resource-group $RG_NAME --name $APP_NAME

# Common issues:
# 1. Database connection failed - check firewall rules
# 2. Port mismatch - verify WEBSITES_PORT=80
# 3. Image pull failed - check ghcr.io access
```

### Database Connection Errors

```bash
# Test connectivity from App Service
az webapp ssh --resource-group $RG_NAME --name $APP_NAME

# Inside container
mysql -h <db-host> -u adminuser -p

# If fails:
# 1. Check firewall rules in database.tf
# 2. Verify credentials in app settings
# 3. Ensure database exists
```

### High Costs

```bash
# View cost analysis
az consumption usage list \
  --start-date 2025-10-01 \
  --end-date 2025-10-22

# Downgrade to save costs
terraform apply -var="app_service_sku=B1" -var="db_sku_name=B_Standard_B1ms"
```

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Or delete resource group (faster)
az group delete --name rg-petclinic-prod --yes
```

## Cost Estimates

| Component | SKU | Monthly Cost |
|-----------|-----|--------------|
| App Service Plan (B1) | Basic | ~$13 |
| App Service Plan (P1v2) | Premium | ~$96 |
| MySQL Flexible (B1ms) | Burstable | ~$20 |
| MySQL Flexible (D2ds_v4) | General Purpose | ~$140 |
| Application Insights | Basic | ~$5-20 |
| **Total (Testing)** | | **~$38** |
| **Total (Production)** | | **~$256** |

## Next Steps

After emergency deployment is stable:

1. **Automate Deployments** - GitHub Actions CI/CD
2. **Enhance Security** - Key Vault, VNet, Private Endpoints
3. **Optimize Performance** - Auto-scaling, CDN
4. **Improve Monitoring** - Custom dashboards, advanced alerts

## Support

- [Azure Documentation](https://learn.microsoft.com/en-us/azure/)
- [Terraform azurerm Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- Implementation Plan: `../../docs/plans/plan-emergency-azure-migration.md`
