# Deployment Runbook - Spring PetClinic on AWS App Runner

**Version:** 2.7.18  
**Last Updated:** 2025-10-22

## Overview

This runbook provides comprehensive step-by-step instructions for deploying the Spring PetClinic application to AWS App Runner. The deployment uses CodePipeline for automated builds and deployments, with support for manual deployment when needed.

## Pre-Deployment Checklist

Before initiating a deployment, ensure the following items are completed:

- [ ] All tests passing (`mvn verify`)
- [ ] Security scan completed (OWASP dependency check)
- [ ] Docker image built and tested locally
- [ ] Environment variables configured in App Runner service
- [ ] Database credentials stored in AWS SSM Parameter Store
- [ ] Staging environment validated (if applicable)
- [ ] Code changes committed and pushed to version control
- [ ] Team notified of upcoming deployment
- [ ] Backup of current production configuration (if available)

## Build Process

### 1. Build Application with Maven

Navigate to the petclinic directory and build the application:

```bash
cd petclinic
mvn clean package -DskipTests
```

**Expected Output:**
- JAR file created at `target/spring-petclinic-2.3.0.jar`
- Build completion message: `BUILD SUCCESS`

**Troubleshooting:**
- If build fails, check Maven is installed: `mvn --version`
- Ensure Java 8 is installed: `java -version`
- Check for dependency issues in `pom.xml`

### 2. Build Docker Image

From the petclinic directory:

```bash
docker build -t petclinic:2.7.18 .
```

**Tag for ECR:**
```bash
# Replace <aws-account-id> and <region> with your values
docker tag petclinic:2.7.18 <aws-account-id>.dkr.ecr.<region>.amazonaws.com/petclinic:2.7.18
docker tag petclinic:2.7.18 <aws-account-id>.dkr.ecr.<region>.amazonaws.com/petclinic:latest
```

**Best Practice:** Always use specific version tags (e.g., `2.7.18`) in addition to `latest` for traceability.

### 3. Test Docker Image Locally

Before pushing to ECR, test the image locally:

```bash
# Run with docker-compose
docker-compose up

# Access at http://localhost:8080
# Test basic functionality:
# - Homepage loads
# - Can view owners
# - Can add pets and visits
```

Stop the containers:
```bash
docker-compose down
```

### 4. Push to Amazon ECR

```bash
# Set environment variables
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
AWS_REGION=$(aws configure get region)

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Push images
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/petclinic:2.7.18
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/petclinic:latest
```

**Verify Push:**
```bash
aws ecr list-images --repository-name petclinic --region $AWS_REGION
```

## Deployment to AWS App Runner

### Via CodePipeline (Recommended)

The automated deployment pipeline is triggered automatically when code is pushed to the CodeCommit repository.

#### Initial Setup

1. **Configure Git credentials:**
   ```bash
   git config --global credential.helper '!aws codecommit credential-helper $@'
   git config --global credential.UseHttpPath true
   ```

2. **Add CodeCommit as remote:**
   ```bash
   cd petclinic
   git remote add origin <codecommit-repo-url>
   ```

3. **Push code to trigger pipeline:**
   ```bash
   git push -u origin master
   ```

#### Monitor Pipeline Progress

1. **Via AWS Console:**
   - Navigate to [AWS CodePipeline Console](https://console.aws.amazon.com/codepipeline)
   - Select the pipeline (e.g., `petclinic-pipeline`)
   - Monitor each stage: Source → Build → Deploy

2. **Via AWS CLI:**
   ```bash
   # Get pipeline execution status
   aws codepipeline get-pipeline-state --name <pipeline-name>
   
   # Watch CodeBuild logs
   aws logs tail /aws/codebuild/<project-name> --follow
   ```

#### Pipeline Stages

1. **Source Stage**
   - Pulls code from CodeCommit
   - Triggered on commit to master branch
   - Duration: ~10 seconds

2. **Build Stage**
   - Runs Maven build: `mvn clean package -Dmaven.test.skip=true`
   - Builds Docker image
   - Pushes to ECR
   - Duration: ~5-10 minutes (first build), ~3-5 minutes (subsequent)

3. **Deploy Stage**
   - App Runner pulls latest image from ECR
   - Deploys new version
   - Performs health checks
   - Routes traffic to new version
   - Duration: ~3-5 minutes

### Manual Deployment (Emergency/Testing)

If CodePipeline is unavailable or you need to deploy manually:

#### 1. Update App Runner Service via Console

1. Navigate to [AWS App Runner Console](https://console.aws.amazon.com/apprunner)
2. Select your service (e.g., `petclinic-service`)
3. Click **Deploy** → **Manual deployment**
4. Confirm deployment

#### 2. Update App Runner Service via CLI

```bash
# Trigger a new deployment
aws apprunner start-deployment \
    --service-arn <service-arn> \
    --region $AWS_REGION

# Monitor deployment status
aws apprunner describe-service \
    --service-arn <service-arn> \
    --region $AWS_REGION \
    --query 'Service.Status'
```

#### 3. Update with Terraform (Infrastructure Changes)

If you need to update App Runner configuration:

```bash
cd terraform

# Review planned changes
terraform plan

# Apply changes
terraform apply

# Verify service status
terraform output apprunner_service_url
```

## Environment Variables

### Required Environment Variables in App Runner

The following environment variables must be configured in the App Runner service:

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `AWS_REGION` | AWS region for SSM parameter access | `us-east-1` |
| `spring.datasource.username` | Database username | `petclinic` |
| `spring.datasource.url` | JDBC connection string | `jdbc:mysql://petclinic-db.xxx.rds.amazonaws.com/petclinic` |
| `spring.sql.init.mode` | Database initialization mode | `always` |
| `spring.profiles.active` | Active Spring profile | `mysql` |

### Secrets Management

**Database Password (via AWS SSM Parameter Store):**

The database password is retrieved at container startup from SSM Parameter Store:

```bash
# Set the parameter (one-time setup)
aws ssm put-parameter \
    --name /database/password \
    --value <your-secure-password> \
    --type SecureString \
    --region $AWS_REGION

# Verify parameter exists
aws ssm get-parameter \
    --name /database/password \
    --with-decryption \
    --region $AWS_REGION
```

**How it works:**
- The Dockerfile ENTRYPOINT retrieves the password at startup
- Uses AWS CLI with container's IAM role
- Password is injected into `spring.datasource.password` environment variable

**Security Best Practices:**
- Never commit passwords to source code
- Use IAM roles for App Runner service to access SSM
- Rotate passwords regularly
- Use AWS Secrets Manager for production (alternative to SSM)

### Configuring Environment Variables

**Via Terraform (recommended for infrastructure):**

Edit `terraform/services.tf`:
```hcl
runtime_environment_variables = {
  "spring.datasource.username" : "${var.db_user}",
  "spring.sql.init.mode" : var.db_initialize_mode,
  "spring.profiles.active" : var.db_profile,
  "spring.datasource.url" : "jdbc:mysql://${aws_db_instance.db.address}/${var.db_name}"
}
```

Then apply:
```bash
terraform apply
```

**Via AWS Console (for quick changes):**
1. Navigate to App Runner service
2. Configuration → Edit
3. Add/modify environment variables
4. Deploy

## Health Checks

### Verify Deployment Success

#### 1. Check App Runner Service Status

**Via Console:**
- Go to [AWS App Runner Console](https://console.aws.amazon.com/apprunner)
- Service status should show "Running"
- Recent deployment should show "Succeeded"

**Via CLI:**
```bash
aws apprunner describe-service \
    --service-arn <service-arn> \
    --query 'Service.[Status,HealthCheckConfiguration]'
```

#### 2. Verify Health Endpoint

The application exposes Spring Boot Actuator health endpoint:

```bash
# Get service URL
cd terraform
export SERVICE_URL=$(terraform output -raw apprunner_service_url)

# Check health endpoint
curl https://${SERVICE_URL}/actuator/health

# Expected response:
# {"status":"UP"}
```

#### 3. Test Application Features

Perform smoke tests on critical functionality:

**Homepage:**
```bash
curl -I https://${SERVICE_URL}/
# Expected: HTTP 200 OK
```

**Manual Testing:**
1. Visit homepage: `https://<service-url>/`
2. Navigate to "Find Owners"
3. Add a new owner
4. Add a pet to the owner
5. Schedule a visit for the pet
6. Verify all data persists correctly

#### 4. Monitor Application Logs

**Via CloudWatch Logs:**
```bash
# Tail logs in real-time
aws logs tail /aws/apprunner/<service-name>/<service-id>/application --follow

# Filter for errors
aws logs tail /aws/apprunner/<service-name>/<service-id>/application \
    --filter-pattern "ERROR" \
    --follow

# Check startup logs
aws logs tail /aws/apprunner/<service-name>/<service-id>/application \
    --since 5m
```

**What to look for:**
- `Started PetClinicApplication` - Application started successfully
- No `ERROR` or `FATAL` messages
- Database connection successful
- No permission denied errors

#### 5. Database Connectivity

Verify database connection:

```bash
# Check logs for database initialization
aws logs tail /aws/apprunner/<service-name>/<service-id>/application \
    --filter-pattern "HikariPool" \
    --since 10m

# Should see: "HikariPool-1 - Start completed."
```

## Rollback Procedures

### Quick Rollback (Previous Container Image)

If the new deployment has issues, rollback to the previous image:

#### Option 1: Via App Runner Console

1. Navigate to App Runner service
2. Go to "Deployments" tab
3. Find previous successful deployment
4. Click "Redeploy"

#### Option 2: Via ECR Tag

```bash
# List recent images
aws ecr describe-images \
    --repository-name petclinic \
    --query 'sort_by(imageDetails,& imagePushedAt)[-5:]' \
    --region $AWS_REGION

# Note the previous image tag/digest
# Update App Runner to use specific tag (via console or terraform)
```

#### Option 3: Git Revert + Pipeline

```bash
# Revert to previous commit
git log --oneline -5
git revert <bad-commit-sha>
git push origin master

# Pipeline will automatically deploy previous version
```

### Full Rollback (Infrastructure + Application)

If infrastructure changes were made, rollback using Terraform:

```bash
cd terraform

# Identify the previous state
git log --oneline terraform/

# Checkout previous version
git checkout <previous-commit> -- terraform/

# Review changes
terraform plan

# Apply rollback
terraform apply

# After verification, commit the rollback
git add terraform/
git commit -m "Rollback infrastructure to previous version"
```

### Database Rollback (If Schema Changed)

**⚠️ CAUTION:** Only perform database rollback if absolutely necessary.

```bash
# If you have a database backup:
# 1. Restore RDS snapshot via AWS Console
# 2. Update App Runner service to point to restored database
# 3. Redeploy application

# For schema-only rollback:
# 1. Apply reverse migration scripts (if available)
# 2. Restart application
```

**Best Practice:** Always test database migrations in staging first.

## Troubleshooting

### Common Issues and Solutions

#### Issue: Application Fails to Start

**Symptoms:**
- App Runner deployment fails
- Logs show application crash
- Health checks failing

**Diagnosis:**
```bash
# Check application logs
aws logs tail /aws/apprunner/<service-name>/<service-id>/application --since 10m

# Look for stack traces and error messages
```

**Solutions:**
1. **Check Java version:** Ensure Dockerfile uses correct Java version (1.8.422)
2. **Verify dependencies:** Ensure all Maven dependencies resolved correctly
3. **Check memory:** Verify App Runner has sufficient memory (2GB recommended)
4. **Review configuration:** Check `application.properties` for errors

#### Issue: Database Connection Errors

**Symptoms:**
- Logs show `CommunicationsException` or `SQLException`
- Application starts but can't access database
- Health checks failing

**Diagnosis:**
```bash
# Check database connection in logs
aws logs tail /aws/apprunner/<service-name>/<service-id>/application \
    --filter-pattern "SQLException"

# Verify database is running
aws rds describe-db-instances \
    --db-instance-identifier <db-name> \
    --query 'DBInstances[0].DBInstanceStatus'
```

**Solutions:**
1. **Verify database URL:** Check `spring.datasource.url` environment variable
   ```bash
   aws apprunner describe-service --service-arn <arn> \
       --query 'Service.SourceConfiguration.ImageRepository.ImageConfiguration.RuntimeEnvironmentVariables'
   ```

2. **Check credentials:**
   ```bash
   # Verify SSM parameter exists
   aws ssm get-parameter --name /database/password --with-decryption
   ```

3. **Security group rules:** Ensure App Runner can reach RDS
   - Check VPC configuration
   - Verify security group allows inbound MySQL (3306)

4. **Database status:** Ensure RDS instance is available

#### Issue: Permission Denied Errors (Non-Root User)

**Symptoms:**
- Container fails to start
- Logs show permission errors
- File system access denied

**Diagnosis:**
```bash
# Check container logs for permission errors
aws logs tail /aws/apprunner/<service-name>/<service-id>/application \
    --filter-pattern "Permission denied"
```

**Solutions:**
1. **Verify Dockerfile:** Ensure proper ownership set
   ```dockerfile
   RUN chown -R spring:spring /app
   USER spring
   ```

2. **Check file permissions:** Rebuild Docker image with correct permissions

3. **Temporary fix:** If urgent, can revert to root user temporarily (not recommended for production)

#### Issue: CodePipeline Build Failures

**Symptoms:**
- Pipeline stuck in "Failed" state
- Build stage shows errors
- No new deployment triggered

**Diagnosis:**
```bash
# Get build logs
aws logs tail /aws/codebuild/<project-name> --follow

# Check build status
aws codebuild batch-get-builds \
    --ids <build-id> \
    --query 'builds[0].[buildStatus,phases]'
```

**Solutions:**
1. **Maven build failure:**
   - Check `pom.xml` for errors
   - Verify dependencies can be downloaded
   - Review compilation errors in logs

2. **Docker build failure:**
   - Ensure JAR file was created successfully
   - Check Dockerfile syntax
   - Verify base image is accessible

3. **ECR push failure:**
   - Verify ECR repository exists
   - Check IAM permissions for CodeBuild role
   - Ensure ECR login succeeds

#### Issue: Slow Deployment / Timeout

**Symptoms:**
- Deployment takes longer than expected
- App Runner stuck in "Deploying" state
- Timeout errors

**Solutions:**
1. **Increase timeout:** Update App Runner health check timeout
2. **Check resource limits:** Ensure adequate CPU/memory
3. **Optimize Docker image:** 
   - Use `.dockerignore` to exclude unnecessary files
   - Minimize layer count
   - Use multi-stage builds (future improvement)

4. **Network issues:** Check VPC connectivity and NAT gateway

#### Issue: Old Version Still Serving Traffic

**Symptoms:**
- Deployment shows success but old version running
- Changes not reflected in application

**Diagnosis:**
```bash
# Check running image
aws apprunner describe-service --service-arn <arn> \
    --query 'Service.SourceConfiguration.ImageRepository.ImageIdentifier'

# Compare with latest ECR image
aws ecr describe-images --repository-name petclinic \
    --image-ids imageTag=latest
```

**Solutions:**
1. **Force new deployment:** Trigger manual deployment via console
2. **Clear browser cache:** Old assets may be cached
3. **Verify image tag:** Ensure App Runner is using `:latest` or specific version tag
4. **Check deployment status:** Ensure deployment actually completed

### Debug Mode

To enable debug logging for troubleshooting:

**Temporary (via environment variable):**
Add to App Runner environment variables:
```
JAVA_OPTS=-Dlogging.level.org.springframework=DEBUG
```

**Permanent (via application.properties):**
Uncomment in `src/main/resources/application.properties`:
```properties
logging.level.org.springframework.web=DEBUG
```

## Security Notes

### Application Security

- **Non-root user:** Application runs as user `spring` (UID/GID created in Dockerfile)
- **Minimal base image:** Uses Bitnami Java 1.8.422 (specific version, not `latest`)
- **No secrets in code:** All credentials via environment variables or SSM
- **HTTPS only:** App Runner enforces HTTPS for all external traffic

### Infrastructure Security

- **IAM roles:** App Runner uses IAM role to access AWS resources (no access keys)
- **Secrets Manager/SSM:** Database password stored encrypted in SSM Parameter Store
- **VPC isolation:** RDS database in private subnets (not publicly accessible)
- **Security groups:** Restrictive rules (only App Runner can access RDS)

### Image Security

- **Version pinning:** Docker image uses specific Java version (`1.8.422`)
- **Vulnerability scanning:** ECR automatically scans images on push
- **Minimal layers:** Optimized Dockerfile reduces attack surface
- **Dependency updates:** Regular updates to Spring Boot and libraries

### Audit and Compliance

```bash
# Check ECR scan results
aws ecr describe-image-scan-findings \
    --repository-name petclinic \
    --image-id imageTag=latest

# Review CloudTrail logs for deployment actions
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::AppRunner::Service \
    --max-results 10
```

## Post-Deployment

### Verification Checklist

After deployment completes, verify the following:

- [ ] App Runner service status shows "Running"
- [ ] Health endpoint returns `{"status":"UP"}`
- [ ] Homepage loads successfully
- [ ] Can create new owner
- [ ] Can add pet to owner
- [ ] Can schedule visit
- [ ] No ERROR messages in logs (last 10 minutes)
- [ ] Database queries executing successfully
- [ ] Response times within acceptable range

### Monitoring

**CloudWatch Metrics:**
- Navigate to CloudWatch → Metrics → AppRunner
- Monitor:
  - `RequestCount` - Traffic volume
  - `2xxStatusCount` / `4xxStatusCount` / `5xxStatusCount` - Success/error rates
  - `ActiveInstances` - Number of running instances
  - `CPUUtilization` - CPU usage
  - `MemoryUtilization` - Memory usage

**Set up alarms:**
```bash
# Create alarm for high error rate
aws cloudwatch put-metric-alarm \
    --alarm-name petclinic-high-errors \
    --alarm-description "Alert on high 5xx errors" \
    --metric-name 5xxStatusCount \
    --namespace AWS/AppRunner \
    --statistic Sum \
    --period 300 \
    --threshold 10 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2
```

### Performance Baseline

After first deployment, establish performance baselines:

```bash
# Average response time
curl -o /dev/null -s -w "Time: %{time_total}s\n" https://${SERVICE_URL}/

# Run load test (using Apache Bench)
ab -n 1000 -c 10 https://${SERVICE_URL}/

# Monitor during load test
aws cloudwatch get-metric-statistics \
    --namespace AWS/AppRunner \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value=petclinic-service \
    --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 60 \
    --statistics Average
```

### Documentation Updates

- [ ] Update deployment history log
- [ ] Document any configuration changes
- [ ] Note any issues encountered and resolutions
- [ ] Update runbook if new steps discovered
- [ ] Communicate deployment completion to team

### Team Notification

Send deployment notification with:
- Version deployed (commit SHA or tag)
- Deployment time
- Any known issues or changes in behavior
- Verification test results
- Next deployment scheduled time (if known)

## Additional Resources

### AWS Documentation
- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [AWS CodePipeline User Guide](https://docs.aws.amazon.com/codepipeline/)
- [Amazon ECR User Guide](https://docs.aws.amazon.com/ecr/)
- [AWS SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)

### Spring Boot Documentation
- [Spring Boot 2.7 Reference](https://docs.spring.io/spring-boot/docs/2.7.x/reference/html/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/2.7.x/reference/html/actuator.html)
- [Spring Data JPA](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/)

### Related Documentation
- Implementation plan: `docs/plans/plan-critical-security-fixes.md`
- Code assessment: `docs/initial-code-assessment.md`
- Main README: `README.md`

### Useful Commands Reference

```bash
# Quick status check
aws apprunner list-services --query 'ServiceSummaryList[*].[ServiceName,Status]'

# Get service URL
terraform output apprunner_service_url

# Tail logs
aws logs tail /aws/apprunner/<service-name>/<service-id>/application --follow

# List recent deployments
aws apprunner list-operations --service-arn <arn>

# Check ECR images
aws ecr list-images --repository-name petclinic

# Database status
aws rds describe-db-instances --db-instance-identifier <db-name> \
    --query 'DBInstances[0].DBInstanceStatus'
```

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-22 | GitHub Copilot | Initial runbook creation with Spring Boot 2.7.18 updates |

---

**For assistance or questions, contact the DevOps team or refer to the troubleshooting section above.**
