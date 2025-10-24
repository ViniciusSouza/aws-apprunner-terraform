---
goal: "Emergency Azure Migration - Fast-Track Deployment"
status: in-progress
created: 2025-10-22
started: 2025-10-22
estimated_effort: large
sprint: 2
priority: URGENT
delegate_to_agent: true
agent_tasks: 3
agent_tasks_completed: 3
tasks_total: 12
tasks_completed: 5
---

# Implementation Plan: Emergency Azure Migration (Fast-Track)

## 🚨 Emergency Context

**Situation:** AWS outage impacting production  
**Objective:** Get PetClinic running on Azure within 2-3 days  
**Strategy:** Minimum viable migration → incremental improvements

## 🎯 Objective

Deploy Spring PetClinic to Azure with **minimum changes** to get operational quickly:
- Azure App Service (simplest Azure compute option)
- Azure Database for MySQL (managed database)
- GitHub Container Registry (avoid Azure CR setup initially)
- Manual deployment first (automate later)

**Post-Migration:** We'll create follow-up plans for CI/CD, monitoring, and optimization.

## 📋 Prerequisites

- [ ] Azure subscription with appropriate permissions
- [ ] Azure CLI installed (`az --version`)
- [ ] Docker installed locally
- [ ] Current application JAR built (from Sprint 1)
- [ ] Database backup from AWS RDS (if preserving data)
- [ ] Azure Database for MySQL Flexible Server quota available

## 🔧 Implementation Tasks

### Phase 1: Azure Infrastructure Setup (DAY 1 - Morning)

**Estimated Time:** 2-3 hours

1. [ ] **Create Azure Resource Group**
   - Files: `azure/terraform/main.tf` (NEW)
   - Details: Central resource group for all Azure resources
   - Commands:
     ```bash
     az group create --name rg-petclinic-prod --location eastus
     ```
   - Agent: No

2. [ ] **Provision Azure Database for MySQL Flexible Server**
   - Files: `azure/terraform/database.tf` (NEW)
   - Details: 
     - MySQL 8.0 (upgrade from 5.7 - compatible with current schema)
     - Burstable SKU (B1ms) for cost efficiency during migration
     - Public access enabled initially (secure later)
     - Firewall rule for your IP + Azure services
   - Risk: Medium - Database version upgrade, but schema is simple
   - Agent: No

3. [ ] **Configure Database Connection Security**
   - Files: `azure/terraform/database.tf`
   - Details:
     - Create database `petclinic`
     - Create user with appropriate permissions
     - Allow Azure services access
     - Temporarily allow public access for migration
   - Agent: No

4. [ ] **Migrate Database Data (if needed)**
   - Files: N/A (manual process)
   - Details:
     - Option A: Fresh start (run schema/data.sql from repo)
     - Option B: Migrate from AWS RDS dump
     - Use MySQL Workbench or `mysql` CLI
   - Commands:
     ```bash
     # Fresh start
     mysql -h <azure-db>.mysql.database.azure.com -u adminuser -p petclinic < src/main/resources/db/mysql/schema.sql
     mysql -h <azure-db>.mysql.database.azure.com -u adminuser -p petclinic < src/main/resources/db/mysql/data.sql
     
     # OR migrate from AWS
     mysqldump -h <aws-rds-endpoint> -u <user> -p petclinic > aws_backup.sql
     mysql -h <azure-db>.mysql.database.azure.com -u adminuser -p petclinic < aws_backup.sql
     ```
   - Risk: Medium - Data migration requires validation
   - Agent: No

### Phase 2: Container & App Service Deployment (DAY 1 - Afternoon)

**Estimated Time:** 3-4 hours

5. [ ] **Build and Test Docker Image Locally**
   - Files: `petclinic/Dockerfile` (already updated in Sprint 1)
   - Details:
     - Build with Spring Boot 2.7.18 JAR
     - Test locally with docker-compose
     - Verify non-root user works
   - Commands:
     ```bash
     cd petclinic
     mvn clean package -DskipTests
     docker build -t petclinic:azure .
     docker run -p 8080:80 \
       -e MYSQL_URL="jdbc:mysql://<azure-db>.mysql.database.azure.com/petclinic" \
       -e MYSQL_USER="adminuser" \
       -e MYSQL_PASS="<password>" \
       petclinic:azure
     ```
   - Agent: No

6. [ ] **Push Image to GitHub Container Registry**
   - Files: `.github/workflows/docker-build.yml` (NEW)
   - Details:
     - Use GitHub Container Registry (ghcr.io) - fastest to set up
     - No Azure Container Registry setup needed initially
     - Tag with version and latest
   - Commands:
     ```bash
     echo $GITHUB_TOKEN | docker login ghcr.io -u ViniciusSouza --password-stdin
     docker tag petclinic:azure ghcr.io/viniciusouza/petclinic:2.7.18
     docker tag petclinic:azure ghcr.io/viniciusouza/petclinic:latest
     docker push ghcr.io/viniciusouza/petclinic:2.7.18
     docker push ghcr.io/viniciusouza/petclinic:latest
     ```
   - Agent: No

7. [ ] **Create Azure App Service Plan**
   - Files: `azure/terraform/app-service.tf` (NEW)
   - Details:
     - Linux plan (required for containers)
     - Premium V2 P1v2 (or B1 for cost savings during testing)
     - Same region as database
   - Commands:
     ```bash
     az appservice plan create \
       --name plan-petclinic-prod \
       --resource-group rg-petclinic-prod \
       --is-linux \
       --sku P1V2
     ```
   - Agent: No

8. [ ] **Create Azure App Service (Web App)**
   - Files: `azure/terraform/app-service.tf`
   - Details:
     - Container deployment from GitHub Container Registry
     - Environment variables for database connection
     - Health check endpoint: `/actuator/health`
     - HTTPS only
   - Commands:
     ```bash
     az webapp create \
       --resource-group rg-petclinic-prod \
       --plan plan-petclinic-prod \
       --name petclinic-prod-<unique-id> \
       --deployment-container-image-name ghcr.io/viniciusouza/petclinic:latest
     
     # Configure environment variables
     az webapp config appsettings set \
       --resource-group rg-petclinic-prod \
       --name petclinic-prod-<unique-id> \
       --settings \
         MYSQL_URL="jdbc:mysql://<azure-db>.mysql.database.azure.com/petclinic?useSSL=true&requireSSL=false" \
         MYSQL_USER="adminuser" \
         MYSQL_PASS="<password>" \
         SPRING_PROFILES_ACTIVE="mysql" \
         WEBSITES_PORT="80"
     ```
   - Agent: No

### Phase 3: Validation & Cutover (DAY 2)

**Estimated Time:** 4-6 hours

9. [ ] **Test Application Functionality**
   - Files: N/A (manual testing)
   - Details:
     - Visit `https://petclinic-prod-<unique-id>.azurewebsites.net`
     - Test all features:
       - ✓ View veterinarians
       - ✓ Find owners
       - ✓ Create new owner
       - ✓ Add pet to owner
       - ✓ Schedule visit
     - Verify database persistence
     - Check application logs in Azure Portal
   - Risk: Medium - May discover runtime issues
   - Agent: No

10. [ ] **Configure Custom Domain (if needed)**
    - Files: `azure/terraform/app-service.tf`
    - Details:
      - Add custom domain binding
      - Configure SSL certificate (Azure managed certificate)
      - Update DNS CNAME record
    - Commands:
      ```bash
      az webapp config hostname add \
        --webapp-name petclinic-prod-<unique-id> \
        --resource-group rg-petclinic-prod \
        --hostname petclinic.yourdomain.com
      
      az webapp config ssl bind \
        --certificate-thumbprint <thumbprint> \
        --ssl-type SNI \
        --name petclinic-prod-<unique-id> \
        --resource-group rg-petclinic-prod
      ```
    - Agent: No
    - Optional: Can skip initially if not critical

11. [ ] **Enable Basic Monitoring**
    - Files: `azure/terraform/monitoring.tf` (NEW)
    - Details:
      - Enable Application Insights (basic)
      - Configure health check ping
      - Set up basic alerts (app down, high response time)
    - Commands:
      ```bash
      az monitor app-insights component create \
        --app petclinic-insights \
        --location eastus \
        --resource-group rg-petclinic-prod \
        --application-type web
      
      # Link to App Service
      az webapp config appsettings set \
        --resource-group rg-petclinic-prod \
        --name petclinic-prod-<unique-id> \
        --settings APPINSIGHTS_INSTRUMENTATIONKEY="<key>"
      ```
    - Agent: No

12. [ ] **Update DNS/Traffic Cutover**
    - Files: N/A (DNS management)
    - Details:
      - Switch DNS from AWS App Runner to Azure App Service
      - Monitor for errors
      - Keep AWS running as fallback initially
    - Risk: High - Production cutover
    - Rollback: Revert DNS to AWS if issues
    - Agent: No

## 🤖 GitHub Copilot Agent Tasks

Tasks to delegate for **parallel execution** while main migration is happening:

1. [ ] **Create Azure-specific documentation**
   - Type: documentation
   - Files: `docs/azure-deployment-guide.md` (NEW)
   - Instructions:
     - Document Azure architecture (App Service + Azure Database)
     - Step-by-step deployment instructions
     - Environment variables reference
     - Troubleshooting guide for Azure-specific issues
     - Cost estimation breakdown
   - Dependencies: Tasks 7, 8 (App Service creation)
   - Priority: Medium

2. [ ] **Create Terraform Azure infrastructure code**
   - Type: infrastructure-as-code
   - Files: 
     - `azure/terraform/main.tf` (NEW)
     - `azure/terraform/variables.tf` (NEW)
     - `azure/terraform/database.tf` (NEW)
     - `azure/terraform/app-service.tf` (NEW)
     - `azure/terraform/monitoring.tf` (NEW)
     - `azure/terraform/outputs.tf` (NEW)
   - Instructions:
     - Convert manual Azure CLI commands to Terraform
     - Use azurerm provider ~> 3.0
     - Include all resources created manually
     - Add outputs for connection strings, URLs
     - Include README with usage instructions
   - Dependencies: Tasks 1-11 (manual deployment complete)
   - Priority: High (needed for reproducibility)

3. [ ] **Create GitHub Actions CI/CD Pipeline**
   - Type: automation
   - Files: `.github/workflows/azure-deploy.yml` (NEW)
   - Instructions:
     - Build Docker image on push to main
     - Push to GitHub Container Registry
     - Deploy to Azure App Service
     - Run health checks
     - Notify on success/failure
     - Include manual approval gate for production
   - Dependencies: Tasks 6, 8 (container and app service setup)
   - Priority: High (automate future deployments)

## 📁 Files to Create/Modify

### New Files (Azure Infrastructure)
- `azure/terraform/main.tf` - Main Terraform configuration
- `azure/terraform/variables.tf` - Variable definitions
- `azure/terraform/database.tf` - Azure Database for MySQL
- `azure/terraform/app-service.tf` - App Service and Plan
- `azure/terraform/monitoring.tf` - Application Insights
- `azure/terraform/outputs.tf` - Output values
- `azure/README.md` - Azure deployment instructions

### New Files (CI/CD)
- `.github/workflows/azure-deploy.yml` - GitHub Actions workflow
- `.github/workflows/docker-build.yml` - Docker build workflow

### New Files (Documentation)
- `docs/azure-deployment-guide.md` - Azure-specific deployment guide
- `docs/azure-migration-runbook.md` - Step-by-step migration runbook
- `docs/azure-troubleshooting.md` - Azure-specific troubleshooting

### Modified Files
- `README.md` - Update with Azure deployment instructions
- `petclinic/src/main/resources/application-mysql.properties` - Azure-specific defaults (optional)

### No Changes Required
- `petclinic/Dockerfile` - ✅ Already updated in Sprint 1
- `petclinic/docker-compose.yml` - ✅ Already updated in Sprint 1
- `petclinic/pom.xml` - ✅ Already updated in Sprint 1
- Application source code - ✅ No changes needed

## 🧪 Testing Strategy

### 1. Local Testing (Pre-deployment)
```bash
# Test with Azure Database connection
docker run -p 8080:80 \
  -e MYSQL_URL="jdbc:mysql://<azure-db>.mysql.database.azure.com/petclinic" \
  -e MYSQL_USER="adminuser" \
  -e MYSQL_PASS="<password>" \
  petclinic:azure

# Expected: Application starts, connects to Azure DB
```

### 2. Azure App Service Testing
- **Health Check**: `https://<app>.azurewebsites.net/actuator/health`
- **Homepage**: `https://<app>.azurewebsites.net/`
- **Database Test**: Create owner, verify persistence

### 3. Load Testing (Optional, if time permits)
```bash
# Simple load test with curl
for i in {1..100}; do
  curl -s https://<app>.azurewebsites.net/ > /dev/null &
done
```

### 4. Monitoring Validation
- Check Application Insights for requests
- Verify no errors in App Service logs
- Confirm database connections in Azure Portal

## ⚠️ Risks & Mitigation

### Critical Risks

1. **Database Migration Data Loss**
   - **Risk:** Data corruption during AWS→Azure migration
   - **Mitigation:** 
     - Take AWS RDS snapshot before migration
     - Test restore on Azure with sample data first
     - Validate row counts match after migration
   - **Rollback:** Restore from AWS snapshot

2. **Application Won't Start on Azure**
   - **Risk:** Configuration differences break application
   - **Mitigation:**
     - Test locally with Azure database first
     - Review App Service logs immediately
     - Common issues: WEBSITES_PORT, Java version, memory limits
   - **Rollback:** Keep AWS running, revert DNS

3. **Performance Issues on Azure**
   - **Risk:** Different VM sizing impacts performance
   - **Mitigation:**
     - Start with P1v2 (recommended for production)
     - Monitor Application Insights
     - Can scale up quickly if needed
   - **Rollback:** Scale up App Service Plan

### Medium Risks

4. **MySQL 8.0 Compatibility**
   - **Risk:** MySQL 5.7→8.0 has breaking changes
   - **Mitigation:**
     - PetClinic schema is simple, should be compatible
     - Test schema creation before full migration
     - SQL mode differences documented
   - **Rollback:** Use MySQL 5.7 if Azure supports it

5. **Cost Overrun**
   - **Risk:** Azure costs higher than expected
   - **Mitigation:**
     - Use B1 App Service Plan initially (~$13/month)
     - Use Burstable database tier (~$20/month)
     - Set up cost alerts
   - **Optimization:** Right-size after monitoring usage

6. **Network Connectivity Issues**
   - **Risk:** App Service can't reach database
   - **Mitigation:**
     - Allow Azure services in database firewall
     - Use VNet integration only after basic setup works
   - **Troubleshooting:** Check NSG rules, connection strings

## ✅ Acceptance Criteria

### Day 1 (Critical)
- [ ] Azure Database for MySQL created and accessible
- [ ] Database schema deployed successfully
- [ ] Docker image built and pushed to GitHub Container Registry
- [ ] Azure App Service created and running
- [ ] Application accessible via `https://<app>.azurewebsites.net`
- [ ] Basic health check passing

### Day 2 (Validation)
- [ ] All application features working (view vets, owners, pets, visits)
- [ ] Data persists correctly in Azure Database
- [ ] No critical errors in Application Insights
- [ ] Application Insights capturing requests
- [ ] Basic alerts configured (app down, errors)

### Day 3 (Production Ready)
- [ ] DNS cutover complete (if applicable)
- [ ] Custom domain configured with SSL
- [ ] Production data migrated (if applicable)
- [ ] Monitoring dashboards set up
- [ ] Documentation updated
- [ ] Team trained on Azure Portal basics

### Post-Migration (Agent Tasks)
- [ ] Terraform code created for infrastructure reproducibility
- [ ] CI/CD pipeline automated
- [ ] Comprehensive Azure documentation complete

## 🔄 Dependencies

### External Dependencies
- Azure subscription with credits/budget
- GitHub account for Container Registry
- Access to AWS RDS for data export (if migrating data)
- DNS provider access (for custom domain)

### Task Dependencies
- Tasks 5-8 depend on Task 2 (database must exist)
- Task 9 depends on Task 8 (app service must be deployed)
- Task 10 depends on Task 9 (app must be working)
- Task 12 depends on Task 9 (validated before cutover)
- Agent Task 2 depends on Tasks 1-11 (manual steps document what to automate)
- Agent Task 3 depends on Tasks 6, 8 (container and app service setup)

## 📝 Implementation Notes

### Azure vs AWS Equivalents

| AWS Service | Azure Equivalent | Notes |
|-------------|------------------|-------|
| App Runner | App Service | Similar managed container hosting |
| RDS MySQL 5.7 | Azure Database for MySQL 8.0 | Version upgrade required |
| ECR | GitHub Container Registry | Using ghcr.io initially, ACR later |
| CodePipeline | GitHub Actions | Simpler setup for emergency |
| SSM Parameter Store | App Settings | Built into App Service |
| CloudWatch | Application Insights | Better integration with App Service |
| VPC | Virtual Network | Optional for Phase 1 |

### Cost Estimates (Monthly)

**Minimal Configuration:**
- App Service B1: ~$13/month
- Azure Database B1ms: ~$20/month
- Application Insights: ~$5/month (basic tier)
- **Total: ~$38/month** (much cheaper than AWS during testing)

**Production Configuration:**
- App Service P1v2: ~$96/month
- Azure Database GP_Gen5_2: ~$140/month
- Application Insights: ~$20/month
- **Total: ~$256/month**

### Environment Variables Required

```bash
# App Service Application Settings
MYSQL_URL="jdbc:mysql://<server>.mysql.database.azure.com/petclinic?useSSL=true&requireSSL=false"
MYSQL_USER="adminuser"
MYSQL_PASS="<password>"
SPRING_PROFILES_ACTIVE="mysql"
WEBSITES_PORT="80"

# Optional for Application Insights
APPINSIGHTS_INSTRUMENTATIONKEY="<key>"
APPLICATIONINSIGHTS_CONNECTION_STRING="<connection-string>"
```

### Quick Command Reference

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "<subscription-id>"

# Create Resource Group
az group create --name rg-petclinic-prod --location eastus

# Create MySQL Flexible Server
az mysql flexible-server create \
  --resource-group rg-petclinic-prod \
  --name petclinic-mysql-prod \
  --admin-user adminuser \
  --admin-password '<SecurePassword123!>' \
  --sku-name Standard_B1ms \
  --version 8.0 \
  --storage-size 32 \
  --public-access 0.0.0.0 \
  --location eastus

# Create database
az mysql flexible-server db create \
  --resource-group rg-petclinic-prod \
  --server-name petclinic-mysql-prod \
  --database-name petclinic

# Build and push Docker image
docker build -t petclinic:azure petclinic/
echo $GITHUB_TOKEN | docker login ghcr.io -u ViniciusSouza --password-stdin
docker tag petclinic:azure ghcr.io/viniciusouza/petclinic:latest
docker push ghcr.io/viniciusouza/petclinic:latest

# Create App Service Plan
az appservice plan create \
  --name plan-petclinic-prod \
  --resource-group rg-petclinic-prod \
  --is-linux \
  --sku P1V2 \
  --location eastus

# Create Web App
az webapp create \
  --resource-group rg-petclinic-prod \
  --plan plan-petclinic-prod \
  --name petclinic-prod-$RANDOM \
  --deployment-container-image-name ghcr.io/viniciusouza/petclinic:latest

# Configure app settings
az webapp config appsettings set \
  --resource-group rg-petclinic-prod \
  --name petclinic-prod-<id> \
  --settings \
    MYSQL_URL="jdbc:mysql://petclinic-mysql-prod.mysql.database.azure.com/petclinic" \
    MYSQL_USER="adminuser" \
    MYSQL_PASS="<password>" \
    SPRING_PROFILES_ACTIVE="mysql" \
    WEBSITES_PORT="80"

# View logs
az webapp log tail \
  --resource-group rg-petclinic-prod \
  --name petclinic-prod-<id>
```

## 🚀 Fast-Track Timeline

### Day 1: Deploy
- **Morning (3 hours):** Infrastructure setup (Tasks 1-4)
- **Afternoon (4 hours):** Container & App Service (Tasks 5-8)
- **Evening:** Initial testing

### Day 2: Validate
- **Morning (3 hours):** Comprehensive testing (Task 9)
- **Afternoon (3 hours):** Monitoring & domain setup (Tasks 10-11)
- **Evening:** Final validation

### Day 3: Cutover
- **Morning:** Final smoke tests
- **Afternoon:** DNS cutover (Task 12)
- **Evening:** Monitor production, verify stability

### Ongoing: Automation
- **Agent Tasks:** Running in parallel
- **Review & Merge:** Terraform code and CI/CD pipeline

## 🔜 Follow-Up Plans

After emergency migration is stable, create follow-up plans for:

1. **Sprint 3: Azure Security Hardening**
   - Azure Key Vault for secrets
   - VNet integration
   - Private endpoints for database
   - Azure AD authentication

2. **Sprint 4: Azure Optimization**
   - Azure Container Registry
   - Azure Front Door (CDN)
   - Auto-scaling configuration
   - Cost optimization review

3. **Sprint 5: Advanced Monitoring**
   - Custom Application Insights dashboards
   - Advanced alerting
   - Performance tuning
   - Availability tests

## 📚 References

- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Azure Database for MySQL](https://learn.microsoft.com/en-us/azure/mysql/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Spring Boot on Azure](https://learn.microsoft.com/en-us/azure/developer/java/spring-framework/)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/)

---

**PRIORITY:** URGENT - Production outage mitigation  
**TIMELINE:** 2-3 days for basic deployment  
**TEAM:** Primary developer + Agent tasks for automation  
**SUCCESS CRITERIA:** Application running on Azure, accessible to users
