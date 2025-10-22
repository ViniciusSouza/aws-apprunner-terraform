# Code Assessment Upgrade Plan

**Plan Version:** 1.0  
**Created:** October 22, 2025  
**Repository:** aws-apprunner-terraform  
**Project:** Spring PetClinic on AWS App Runner

---

## Table of Contents

1. [Overview](#overview)
2. [Pre-Upgrade Preparation](#pre-upgrade-preparation)
3. [Phase 1: Foundation Upgrades](#phase-1-foundation-upgrades)
4. [Phase 2: Application Modernization](#phase-2-application-modernization)
5. [Phase 3: Infrastructure Updates](#phase-3-infrastructure-updates)
6. [Phase 4: Security Hardening](#phase-4-security-hardening)
7. [Phase 5: Testing & Validation](#phase-5-testing--validation)
8. [Rollback Strategy](#rollback-strategy)
9. [Timeline & Resources](#timeline--resources)

---

## Overview

### Objectives
- Eliminate all EOL dependencies and security vulnerabilities
- Modernize application stack to current LTS versions
- Improve application performance and maintainability
- Enhance security posture across all layers
- Establish sustainable upgrade practices

### Success Criteria
- ✅ All components on supported versions
- ✅ Zero critical security vulnerabilities
- ✅ All tests passing with ≥80% code coverage
- ✅ Performance equal or better than current baseline
- ✅ Successful deployment to staging and production

### Risk Assessment
- **Overall Risk Level:** High (major version changes across multiple components)
- **Mitigation:** Phased approach with comprehensive testing at each stage
- **Rollback Capability:** Full rollback plan maintained throughout

---

## Pre-Upgrade Preparation

### 1. Environment Setup

#### Create Feature Branch
```bash
git checkout -b feature/major-version-upgrades
git push -u origin feature/major-version-upgrades
```

#### Set Up Local Development Environment
```bash
# Install required tools
# Java 17 SDK
# Maven 3.9+
# Docker Desktop
# Terraform 1.5+
# AWS CLI v2

# Verify installations
java -version
mvn -version
docker --version
terraform version
aws --version
```

### 2. Baseline Documentation

#### Current System Metrics
**Action Items:**
- [ ] Document current application startup time
- [ ] Record memory usage patterns
- [ ] Capture response time benchmarks (p50, p95, p99)
- [ ] Document current container image sizes
- [ ] List all current API endpoints and their behavior
- [ ] Export current database schema

**Commands:**
```bash
# Document current Docker image size
docker images | grep petclinic

# Export current database schema
mysqldump -h <rds-endpoint> -u root -p --no-data petclinic > schema_baseline.sql

# Performance baseline (if deployed)
# Use tools like JMeter, k6, or Apache Bench
```

### 3. Backup Strategy

#### Code Backup
```bash
# Tag current stable version
git tag -a v2.3.0-stable -m "Stable version before major upgrades"
git push origin v2.3.0-stable
```

#### Infrastructure Backup
```bash
# Terraform state backup
cd terraform
terraform state pull > terraform-state-backup-$(date +%Y%m%d).json

# RDS snapshot (via AWS Console or CLI)
aws rds create-db-snapshot \
  --db-instance-identifier petclinic \
  --db-snapshot-identifier petclinic-pre-upgrade-$(date +%Y%m%d)
```

### 4. Test Environment Setup

**Action Items:**
- [ ] Create isolated staging environment
- [ ] Deploy current version to staging
- [ ] Verify staging matches production
- [ ] Set up automated testing framework
- [ ] Configure monitoring and logging

---

## Phase 1: Foundation Upgrades
**Duration:** 2-3 weeks  
**Risk Level:** High  

### Step 1.1: Upgrade Java to 17 LTS

**Estimated Time:** 2-3 days

#### Update pom.xml
```xml
<properties>
    <!-- Change from java.version>1.8 to: -->
    <java.version>17</java.version>
    <!-- ... -->
</properties>
```

#### Update Dockerfile
```dockerfile
# Change from:
# FROM public.ecr.aws/bitnami/java:latest

# To:
FROM public.ecr.aws/bitnami/java:17-prod
```

#### Validation Steps
```bash
# Compile project
cd petclinic
mvn clean compile

# Check for Java 17 specific issues
mvn dependency:tree
mvn versions:display-plugin-updates
```

#### Expected Issues & Resolutions
| Issue | Resolution |
|-------|------------|
| Illegal reflective access warnings | Add JVM flags: `--add-opens` if needed |
| Removed APIs (e.g., Java EE modules) | Add explicit dependencies to pom.xml |
| Changed garbage collection defaults | Review and update GC settings if customized |

**Testing:**
- [ ] Unit tests pass
- [ ] Application starts successfully
- [ ] No runtime errors in logs
- [ ] Manual smoke testing of key features

---

### Step 1.2: Upgrade Spring Boot 2.3 → 2.7 (Intermediate Step)

**Estimated Time:** 3-5 days

#### Update pom.xml Parent Version
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <!-- Change from version>2.3.3.RELEASE to: -->
    <version>2.7.18</version>
</parent>
```

#### Required Configuration Changes

**1. Update application.properties**
```properties
# DEPRECATED: spring.datasource.initialization-mode
# NEW: spring.sql.init.mode
spring.sql.init.mode=always

# Add if using circular dependencies (temporary)
spring.main.allow-circular-references=true
```

**2. Update dependency versions in pom.xml**
```xml
<properties>
    <!-- Update web jars for compatibility -->
    <webjars-bootstrap.version>5.3.0</webjars-bootstrap.version>
    <webjars-jquery.version>3.7.1</webjars-jquery.version>
    <webjars-jquery-ui.version>1.13.2</webjars-jquery-ui.version>
    
    <!-- Update tool versions -->
    <jacoco.version>0.8.12</jacoco.version>
    <spring-format.version>0.0.41</spring-format.version>
</properties>
```

**3. Update Maven plugins**
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-checkstyle-plugin</artifactId>
    <version>3.3.1</version>
    <dependencies>
        <dependency>
            <groupId>com.puppycrawl.tools</groupId>
            <artifactId>checkstyle</artifactId>
            <version>10.12.4</version>
        </dependency>
    </dependencies>
</plugin>
```

#### Migration Guide Steps
```bash
# Clean and rebuild
mvn clean install

# Run all tests
mvn test

# Check for deprecation warnings
mvn clean package | grep -i "deprecated\|warning"
```

#### Breaking Changes to Address
- **Actuator endpoints:** Some endpoint paths may have changed
- **Security configuration:** Review if using Spring Security
- **Hibernate configuration:** May need updates if using JPA
- **Circular dependencies:** Address and eliminate rather than allow

**Testing:**
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Application starts and connects to database
- [ ] All REST endpoints functional
- [ ] Frontend renders correctly
- [ ] No errors in application logs

---

### Step 1.3: Update Frontend Dependencies

**Estimated Time:** 2-3 days

#### Bootstrap 3.3.6 → 5.3.0 Migration

**Critical Changes:**
1. **Grid System:** `.col-xs-*` removed, use `.col-*` instead
2. **JavaScript:** Bootstrap 5 requires Popper.js
3. **Forms:** Form markup has changed
4. **Utilities:** Many utility classes renamed

**Update Templates (Thymeleaf):**

Audit all templates in `src/main/resources/templates/`:
```bash
# Find all Bootstrap classes
grep -r "class.*col-" src/main/resources/templates/
grep -r "btn-" src/main/resources/templates/
grep -r "form-" src/main/resources/templates/
```

**Example changes in layout.html:**
```html
<!-- OLD Bootstrap 3: -->
<div class="col-xs-12 col-sm-6">

<!-- NEW Bootstrap 5: -->
<div class="col-12 col-sm-6">
```

#### jQuery 2.2.4 → 3.7.1 Migration

**Breaking Changes:**
1. **$.ajax()** error handling syntax changed
2. **$(selector).size()** removed - use `.length` instead
3. **Load event:** Some timing differences

**Search for problematic patterns:**
```bash
# Find potential issues
grep -r "\.size()" src/main/resources/static/
grep -r "\.bind(" src/main/resources/static/
grep -r "\.unbind(" src/main/resources/static/
```

**Testing:**
- [ ] Visual regression testing on all pages
- [ ] Test all interactive elements (forms, buttons)
- [ ] Cross-browser testing (Chrome, Firefox, Safari, Edge)
- [ ] Mobile responsiveness check
- [ ] JavaScript console shows no errors

---

## Phase 2: Application Modernization
**Duration:** 2-3 weeks  
**Risk Level:** Very High  

### Step 2.1: Upgrade Spring Boot 2.7 → 3.3

**Estimated Time:** 5-7 days

#### Prerequisites
- ✅ Java 17 installed and tested
- ✅ All tests passing on Spring Boot 2.7
- ✅ Code review completed

#### Update pom.xml
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.4</version>
</parent>

<groupId>org.springframework.samples</groupId>
<artifactId>spring-petclinic</artifactId>
<version>3.3.0</version>
```

#### Major Breaking Changes

**1. Jakarta EE Package Rename**

Spring Boot 3 requires Jakarta EE 9+, which renamed packages:
- `javax.persistence.*` → `jakarta.persistence.*`
- `javax.validation.*` → `jakarta.validation.*`
- `javax.servlet.*` → `jakarta.servlet.*`

**Action Required:**
```bash
# Find and replace across project
find src/main/java -type f -name "*.java" -exec sed -i '' 's/javax.persistence/jakarta.persistence/g' {} +
find src/main/java -type f -name "*.java" -exec sed -i '' 's/javax.validation/jakarta.validation/g' {} +
find src/main/java -type f -name "*.java" -exec sed -i '' 's/javax.servlet/jakarta.servlet/g' {} +
```

**2. Spring Security Changes**

If using Spring Security, major changes required:
```java
// OLD (Spring Boot 2.x):
@Override
protected void configure(HttpSecurity http) throws Exception {
    http.authorizeRequests()...
}

// NEW (Spring Boot 3.x):
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.authorizeHttpRequests()...
    return http.build();
}
```

**3. Actuator Property Changes**
```properties
# OLD:
management.endpoints.web.base-path=/actuator

# NEW (if needed):
management.endpoints.web.base-path=/actuator
# (syntax remains but some defaults changed)
```

**4. Hibernate 6 Changes**

Spring Boot 3 uses Hibernate 6, which has breaking changes:
- Criteria API changes
- Type system changes
- HQL syntax updates

#### Update Application Code

**Review and update all classes in:**
```
src/main/java/org/springframework/samples/petclinic/
├── model/          # Check entity annotations
├── repository/     # Check JPA repositories
├── service/        # Check transaction management
├── web/            # Check controller mappings
└── system/         # Check configuration classes
```

**Common patterns to update:**

```java
// Example: Update Entity classes
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.validation.constraints.NotEmpty;

@Entity
public class Owner extends Person {
    @NotEmpty  // Ensure using jakarta.validation
    private String address;
    // ...
}
```

#### Migration Commands
```bash
# Clean everything
mvn clean

# Update dependencies
mvn versions:use-latest-releases

# Compile (expect errors initially)
mvn compile

# Fix compilation errors, then test
mvn test

# Package
mvn package
```

#### Expected Issues & Solutions

| Issue | Solution |
|-------|----------|
| `javax.*` imports not found | Replace with `jakarta.*` |
| Hibernate query compilation errors | Review HQL syntax for Hibernate 6 |
| Test failures due to Spring changes | Update test configurations and mocks |
| Circular dependency errors | Refactor to remove circular dependencies |
| Property binding errors | Review application.properties binding |

**Testing:**
- [ ] All unit tests pass
- [ ] All integration tests pass  
- [ ] Application starts without errors
- [ ] Database schema updates work correctly
- [ ] All CRUD operations functional
- [ ] Actuator endpoints accessible
- [ ] No deprecation warnings in logs

---

### Step 2.2: Update Build Configuration

**Estimated Time:** 1-2 days

#### Update wro4j Configuration

Spring Boot 3 may have conflicts with older resource processors:

```xml
<plugin>
    <groupId>ro.isdc.wro4j</groupId>
    <artifactId>wro4j-maven-plugin</artifactId>
    <version>1.10.1</version>
    <!-- Update configuration if needed -->
</plugin>
```

#### Review and Update All Maven Plugins

```bash
# Check for updates
mvn versions:display-plugin-updates

# Update to latest stable versions
```

**Recommended plugin versions:**
```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <!-- Version inherited from parent -->
        </plugin>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.11.0</version>
        </plugin>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.2.2</version>
        </plugin>
    </plugins>
</build>
```

---

## Phase 3: Infrastructure Updates
**Duration:** 1-2 weeks  
**Risk Level:** Medium  

### Step 3.1: Update Terraform Configuration

**Estimated Time:** 3-4 days

#### Update provider.tf

```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  # Recommended: Add backend configuration
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "apprunner/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "petclinic"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
```

#### Update rds.tf

```hcl
resource "aws_db_instance" "db" {
  identifier              = "petclinic"
  allocated_storage       = 20
  storage_encrypted       = true  # Enable encryption
  engine                  = "mysql"
  engine_version          = "8.0.35"  # Upgrade from 5.7
  port                    = "3306"
  instance_class          = var.db_instance_type
  db_name                 = var.db_name  # Changed from 'name'
  username                = var.db_user
  password                = data.aws_ssm_parameter.dbpassword.value
  availability_zone       = "${var.aws_region}a"
  vpc_security_group_ids  = [aws_security_group.db-sg.id]
  multi_az                = true  # Enable for production
  db_subnet_group_name    = aws_db_subnet_group.db-subnet-grp.id
  parameter_group_name    = aws_db_parameter_group.mysql8.name
  publicly_accessible     = false  # Security: disable public access
  skip_final_snapshot     = false  # Enable final snapshot
  final_snapshot_identifier = "petclinic-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  backup_retention_period = 7  # Enable backups
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name = "${var.stack}-db"
  }
}

# Add parameter group for MySQL 8.0
resource "aws_db_parameter_group" "mysql8" {
  name   = "petclinic-mysql8"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
}
```

#### Update services.tf

```hcl
resource "aws_apprunner_service" "service" {
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.auto-scaling-config.arn
  service_name                   = "apprunner-petclinic"
  
  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner-service-role.arn
    }
    
    image_repository {
      image_configuration {
        port = var.container_port
        
        runtime_environment_variables = {
          "AWS_REGION"                = var.aws_region
          "spring.datasource.username" = var.db_user
          "spring.sql.init.mode"      = var.db_initialize_mode  # Updated property
          "spring.profiles.active"    = var.db_profile
          "spring.datasource.url"     = "jdbc:mysql://${aws_db_instance.db.address}/${var.db_name}"
          "JAVA_OPTS"                 = "-Xmx512m -Xms256m"
        }
      }
      
      image_identifier      = "${data.aws_ecr_repository.image_repo.repository_url}:latest"
      image_repository_type = "ECR"
    }
  }

  instance_configuration {
    instance_role_arn = aws_iam_role.apprunner-instance-role.arn
    cpu               = "1024"
    memory            = "2048"
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/actuator/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  observability_configuration {
    observability_enabled = true
    observability_configuration_arn = aws_apprunner_observability_configuration.observability.arn
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.connector.arn
    }
  }

  depends_on = [
    aws_iam_role.apprunner-service-role,
    aws_db_instance.db,
    aws_route_table.private-route-table,
    null_resource.petclinic_springboot
  ]
}

# Add observability configuration
resource "aws_apprunner_observability_configuration" "observability" {
  observability_configuration_name = "petclinic-observability"

  trace_configuration {
    vendor = "AWSXRAY"
  }
}

# Add VPC connector for database access
resource "aws_apprunner_vpc_connector" "connector" {
  vpc_connector_name = "petclinic-vpc-connector"
  subnets            = aws_subnet.private[*].id
  security_groups    = [aws_security_group.apprunner-sg.id]
}
```

#### Terraform Migration Commands

```bash
cd terraform

# Initialize with new provider versions
terraform init -upgrade

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Review changes (DO NOT APPLY YET)
terraform plan -out=tfplan

# Review the plan carefully
terraform show tfplan

# Apply in staging environment first
terraform apply -target=aws_db_instance.db

# Full apply (after staging validation)
terraform apply
```

**Testing:**
- [ ] Terraform init succeeds
- [ ] Terraform validate passes
- [ ] Terraform plan shows expected changes
- [ ] Apply to staging environment successful
- [ ] Application connects to upgraded database
- [ ] Health checks passing

---

### Step 3.2: Optimize Dockerfile

**Estimated Time:** 1-2 days

#### Multi-Stage Optimized Dockerfile

```dockerfile
# Stage 1: Build stage
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy pom.xml and download dependencies (cached layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build
COPY src ./src
RUN mvn package -DskipTests -B

# Stage 2: Runtime stage
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023

# Install AWS CLI v2
RUN yum install -y aws-cli && \
    yum clean all && \
    rm -rf /var/cache/yum

# Create non-root user
RUN groupadd -r spring && useradd -r -g spring spring

# Set working directory
WORKDIR /app

# Copy JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Change ownership
RUN chown -R spring:spring /app

# Switch to non-root user
USER spring

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Use IAM role for secrets (remove password from entrypoint)
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", \
  "/app/app.jar"]
```

#### Update docker-compose.yml

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: petclinic-mysql
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-petclinic}
      - MYSQL_DATABASE=${MYSQL_DATABASE:-petclinic}
      - MYSQL_USER=${MYSQL_USER:-petclinic}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD:-petclinic}
    volumes:
      - mysql-data:/var/lib/mysql
      - ./src/main/resources/db/mysql:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - petclinic-network

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: petclinic-app
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=mysql
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/petclinic
      - SPRING_DATASOURCE_USERNAME=${MYSQL_USER:-petclinic}
      - SPRING_DATASOURCE_PASSWORD=${MYSQL_PASSWORD:-petclinic}
    depends_on:
      mysql:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    networks:
      - petclinic-network

volumes:
  mysql-data:

networks:
  petclinic-network:
    driver: bridge
```

#### Create .dockerignore

```
.git
.gitignore
README.md
target/
.mvn/
*.md
.github/
terraform/
docs/
plan/
```

**Testing:**
- [ ] Docker build completes successfully
- [ ] Image size reduced (compare before/after)
- [ ] Container starts as non-root user
- [ ] Health check passes
- [ ] Application connects to database
- [ ] docker-compose up works locally

---

### Step 3.3: Database Migration (MySQL 5.7 → 8.0)

**Estimated Time:** 2-3 days

#### Pre-Migration Checklist

```bash
# 1. Backup current database
aws rds create-db-snapshot \
  --db-instance-identifier petclinic \
  --db-snapshot-identifier petclinic-before-mysql8-upgrade

# 2. Export data for verification
mysqldump -h <rds-endpoint> -u root -p petclinic > backup-before-mysql8.sql

# 3. Check for incompatibilities
mysql -h <rds-endpoint> -u root -p petclinic \
  -e "SHOW VARIABLES LIKE '%sql_mode%';"
```

#### Migration Strategy

**Option A: In-Place Upgrade (Recommended for Staging)**
1. Modify RDS instance via AWS Console/CLI
2. AWS handles upgrade automatically
3. Some downtime required

```bash
# Modify DB instance
aws rds modify-db-instance \
  --db-instance-identifier petclinic \
  --engine-version 8.0.35 \
  --allow-major-version-upgrade \
  --apply-immediately
```

**Option B: Blue-Green Deployment (Recommended for Production)**
1. Create new RDS instance with MySQL 8.0
2. Use DMS or mysqldump to migrate data
3. Update application to point to new instance
4. Cutover with minimal downtime

#### Post-Migration Validation

```bash
# 1. Check MySQL version
mysql -h <new-rds-endpoint> -u root -p -e "SELECT VERSION();"

# 2. Verify all tables
mysql -h <new-rds-endpoint> -u root -p petclinic \
  -e "SHOW TABLES;"

# 3. Check for data integrity
mysql -h <new-rds-endpoint> -u root -p petclinic \
  -e "SELECT COUNT(*) FROM owners; SELECT COUNT(*) FROM pets; SELECT COUNT(*) FROM visits;"

# 4. Test application connectivity
# Deploy updated application and verify functionality
```

#### MySQL 8.0 Configuration Updates

```sql
-- Update character set if needed
ALTER DATABASE petclinic CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Verify new authentication (if issues)
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'your-password';
FLUSH PRIVILEGES;
```

**Testing:**
- [ ] Database version confirmed as 8.0.x
- [ ] All tables present and accessible
- [ ] Data integrity verified (record counts match)
- [ ] Application connects successfully
- [ ] All CRUD operations work
- [ ] Performance benchmarks meet or exceed baseline

---

## Phase 4: Security Hardening
**Duration:** 1 week  
**Risk Level:** Low  

### Step 4.1: Implement Secrets Management

**Estimated Time:** 2-3 days

#### Update IAM Role for Secrets Manager

**Create/Update terraform/secrets.tf:**
```hcl
# Create secret in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.stack}/database/password"
  recovery_window_in_days = 7
  
  tags = {
    Name = "${var.stack}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Update IAM policy for App Runner
data "aws_iam_policy_document" "apprunner_secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      aws_secretsmanager_secret.db_password.arn
    ]
  }
}

resource "aws_iam_policy" "apprunner_secrets" {
  name        = "${var.stack}-apprunner-secrets"
  description = "Allow App Runner to access secrets"
  policy      = data.aws_iam_policy_document.apprunner_secrets.json
}

resource "aws_iam_role_policy_attachment" "apprunner_secrets" {
  role       = aws_iam_role.apprunner-instance-role.name
  policy_arn = aws_iam_policy.apprunner_secrets.arn
}
```

#### Update Application for Secrets Manager

**Add dependency to pom.xml:**
```xml
<dependency>
    <groupId>io.awspring.cloud</groupId>
    <artifactId>spring-cloud-aws-starter-secrets-manager</artifactId>
    <version>3.1.0</version>
</dependency>
```

**Update application.properties:**
```properties
# Use Secrets Manager for password
spring.datasource.password=${/petclinic/database/password}
spring.config.import=aws-secretsmanager:
```

#### Update Dockerfile (Remove Password Retrieval)

```dockerfile
# OLD - Remove this:
# ENTRYPOINT env spring.datasource.password=$(aws ssm get-parameter...) java ...

# NEW - Let Spring Boot handle it:
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

**Testing:**
- [ ] Secret created in Secrets Manager
- [ ] IAM role has correct permissions
- [ ] Application retrieves password successfully
- [ ] Database connection established
- [ ] No passwords in logs or environment variables

---

### Step 4.2: Security Group Hardening

**Estimated Time:** 1 day

#### Update security-groups.tf

```hcl
# App Runner security group
resource "aws_security_group" "apprunner-sg" {
  name        = "${var.stack}-apprunner-sg"
  description = "Security group for App Runner service"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow MySQL to RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.db-sg.id]
  }

  egress {
    description = "Allow HTTPS for AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stack}-apprunner-sg"
  }
}

# Database security group
resource "aws_security_group" "db-sg" {
  name        = "${var.stack}-db-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from App Runner only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.apprunner-sg.id]
  }

  # Remove public access ingress rules

  tags = {
    Name = "${var.stack}-db-sg"
  }
}
```

**Testing:**
- [ ] RDS not publicly accessible
- [ ] App Runner can connect to RDS
- [ ] No unnecessary open ports
- [ ] Security group rules follow least privilege

---

### Step 4.3: Enable Encryption and Logging

**Estimated Time:** 1 day

#### Enable RDS Encryption

Already covered in Phase 3.1 with `storage_encrypted = true`

#### Enable CloudWatch Logs

**Update services.tf:**
```hcl
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "apprunner" {
  name              = "/aws/apprunner/${var.stack}"
  retention_in_days = 30

  tags = {
    Name = "${var.stack}-apprunner-logs"
  }
}

# Update observability configuration
resource "aws_apprunner_observability_configuration" "observability" {
  observability_configuration_name = "petclinic-observability"

  trace_configuration {
    vendor = "AWSXRAY"
  }
}
```

#### Enable Application Logging

**Update application.properties:**
```properties
# Logging configuration
logging.level.root=INFO
logging.level.org.springframework.samples.petclinic=DEBUG
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n
logging.pattern.file=%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n
```

**Testing:**
- [ ] CloudWatch Logs receiving application logs
- [ ] RDS encryption enabled
- [ ] X-Ray traces visible
- [ ] Log retention set appropriately

---

## Phase 5: Testing & Validation
**Duration:** 1-2 weeks  
**Risk Level:** Low  

### Step 5.1: Automated Testing

**Estimated Time:** 3-5 days

#### Unit Tests
```bash
cd petclinic
mvn test

# Generate coverage report
mvn jacoco:report

# View report
open target/site/jacoco/index.html
```

**Target:** ≥80% code coverage

#### Integration Tests
```bash
# Start dependencies
docker-compose up -d mysql

# Run integration tests
mvn verify -P integration-tests

# Cleanup
docker-compose down
```

#### End-to-End Tests

Create `e2e-tests.sh`:
```bash
#!/bin/bash

BASE_URL="${1:-http://localhost:8080}"

echo "Testing $BASE_URL..."

# Test home page
curl -f -s "$BASE_URL/" > /dev/null && echo "✓ Home page" || echo "✗ Home page FAILED"

# Test health endpoint
curl -f -s "$BASE_URL/actuator/health" | grep -q "UP" && echo "✓ Health check" || echo "✗ Health check FAILED"

# Test owners list
curl -f -s "$BASE_URL/owners/find" > /dev/null && echo "✓ Find owners page" || echo "✗ Find owners FAILED"

# Test vets list
curl -f -s "$BASE_URL/vets.html" > /dev/null && echo "✓ Vets page" || echo "✗ Vets FAILED"

echo "E2E tests complete"
```

**Testing:**
- [ ] All unit tests pass
- [ ] Code coverage ≥80%
- [ ] Integration tests pass
- [ ] E2E tests pass
- [ ] No errors in test logs

---

### Step 5.2: Performance Testing

**Estimated Time:** 2-3 days

#### Load Testing with JMeter

Use existing test plan:
```bash
# Run JMeter test
jmeter -n -t src/test/jmeter/petclinic_test_plan.jmx \
  -l results.jtl \
  -e -o report

# View report
open report/index.html
```

#### Performance Metrics to Capture

| Metric | Baseline (2.3.0) | Target (3.3.0) | Actual |
|--------|------------------|----------------|--------|
| Startup Time | __ seconds | ≤ baseline | __ |
| Memory Usage (avg) | __ MB | ≤ baseline | __ |
| Response Time p50 | __ ms | ≤ baseline | __ |
| Response Time p95 | __ ms | ≤ baseline | __ |
| Requests/sec | __ | ≥ baseline | __ |
| Error Rate | __% | 0% | __ |

#### Stress Testing
```bash
# Install k6 (if not using JMeter)
# https://k6.io/docs/getting-started/installation/

# Run stress test
k6 run stress-test.js
```

**Testing:**
- [ ] Performance meets or exceeds baseline
- [ ] No memory leaks under load
- [ ] Graceful degradation under stress
- [ ] Auto-scaling works as expected

---

### Step 5.3: Security Scanning

**Estimated Time:** 1-2 days

#### Dependency Vulnerability Scan
```bash
# Maven dependency check
mvn org.owasp:dependency-check-maven:check

# View report
open target/dependency-check-report.html
```

#### Container Image Scanning
```bash
# ECR automatic scanning enabled in ecr.tf
# Or use Trivy locally
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image <your-image>
```

#### SAST (Static Application Security Testing)
```bash
# Using SonarQube or similar
mvn sonar:sonar \
  -Dsonar.projectKey=petclinic \
  -Dsonar.host.url=http://localhost:9000
```

**Testing:**
- [ ] Zero critical vulnerabilities
- [ ] Zero high vulnerabilities
- [ ] Medium/low vulnerabilities documented
- [ ] Security scan reports generated

---

### Step 5.4: Staging Deployment

**Estimated Time:** 2-3 days

#### Deploy to Staging

```bash
# Terraform apply to staging
cd terraform
terraform workspace select staging  # or use separate tfvars
terraform apply -var-file=staging.tfvars

# Tag and push Docker image
cd ../petclinic
docker build -t petclinic:3.3.0 .
docker tag petclinic:3.3.0 <ecr-repo>:staging
docker push <ecr-repo>:staging

# Update App Runner via CodePipeline or manual deployment
```

#### Staging Validation Checklist

- [ ] Application deploys successfully
- [ ] Health checks passing
- [ ] All features functional
- [ ] Database connectivity working
- [ ] Secrets retrieved correctly
- [ ] Logs flowing to CloudWatch
- [ ] Performance acceptable
- [ ] No errors in logs
- [ ] Manual testing by QA team
- [ ] Stakeholder sign-off

---

## Rollback Strategy

### Immediate Rollback (Within 1 Hour of Deployment)

#### Application Rollback
```bash
# Rollback App Runner service
aws apprunner update-service \
  --service-arn <service-arn> \
  --source-configuration ImageRepository={ImageIdentifier=<ecr-repo>:v2.3.0-stable}

# Or via CodePipeline
# Trigger pipeline with previous commit
```

#### Database Rollback
```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier petclinic \
  --db-snapshot-identifier petclinic-pre-upgrade-<date>

# Or point to old instance if using blue-green
```

#### Terraform Rollback
```bash
cd terraform

# Revert to previous state
terraform state pull > current-state-backup.json
terraform state push terraform-state-backup-<date>.json

# Or use git
git revert <commit-hash>
terraform apply
```

### Post-Rollback Verification

- [ ] Application accessible
- [ ] All features working
- [ ] Database queries succeeding
- [ ] No errors in logs
- [ ] Performance normal
- [ ] Monitoring alerts cleared

---

## Timeline & Resources

### Overall Timeline: 8-12 Weeks

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Pre-Upgrade Preparation | 1 week | None |
| Phase 1: Foundation Upgrades | 2-3 weeks | Preparation complete |
| Phase 2: Application Modernization | 2-3 weeks | Phase 1 complete |
| Phase 3: Infrastructure Updates | 1-2 weeks | Phase 2 complete |
| Phase 4: Security Hardening | 1 week | Phase 3 complete |
| Phase 5: Testing & Validation | 1-2 weeks | Phase 4 complete |
| Production Deployment | 1 week | All phases complete |

### Resource Requirements

#### Personnel
- **Lead Developer:** 1 FTE (full project)
- **Backend Developer:** 1 FTE (Phases 1-2)
- **DevOps Engineer:** 1 FTE (Phases 3-4)
- **QA Engineer:** 0.5 FTE (Phase 5)
- **Security Specialist:** 0.25 FTE (Phase 4)

#### Infrastructure
- **Staging Environment:** Required throughout
- **Development Environments:** 1 per developer
- **CI/CD Pipeline:** Existing (updates needed)

### Estimated Costs

| Item | Estimated Cost |
|------|----------------|
| Development Time (240-320 hrs @ $100/hr) | $24,000-$32,000 |
| AWS Infrastructure (staging, additional resources) | $500-$1,000/month |
| Tools & Licenses | $1,000-$2,000 |
| Testing & Validation | $5,000-$8,000 |
| **Total** | **$30,500-$43,000** |

---

## Success Metrics

### Technical Metrics
- ✅ Zero critical security vulnerabilities
- ✅ All components on supported LTS versions
- ✅ ≥80% code coverage
- ✅ Performance within 10% of baseline
- ✅ Zero production incidents during deployment

### Business Metrics
- ✅ Zero downtime during deployment (using blue-green)
- ✅ Project completed within timeline
- ✅ Budget adherence
- ✅ Stakeholder satisfaction

---

## Post-Upgrade Actions

### Documentation
- [ ] Update README with new versions
- [ ] Document new deployment process
- [ ] Update architecture diagrams
- [ ] Create runbooks for common operations

### Knowledge Transfer
- [ ] Team training on Spring Boot 3 features
- [ ] Workshop on new Terraform configuration
- [ ] Security best practices review

### Ongoing Maintenance
- [ ] Establish regular dependency update schedule
- [ ] Set up automated security scanning
- [ ] Implement continuous monitoring
- [ ] Plan next upgrade cycle (18-24 months)

---

## Appendix

### A. Useful Commands Reference

#### Maven
```bash
mvn clean install              # Clean build
mvn dependency:tree            # View dependencies
mvn versions:display-dependency-updates  # Check for updates
mvn test                       # Run tests
mvn package                    # Create JAR
```

#### Docker
```bash
docker build -t petclinic:latest .     # Build image
docker run -p 8080:8080 petclinic:latest  # Run container
docker-compose up -d                    # Start services
docker logs -f <container>              # View logs
```

#### Terraform
```bash
terraform init                 # Initialize
terraform plan                 # Preview changes
terraform apply                # Apply changes
terraform destroy              # Destroy infrastructure
terraform state list           # List resources
```

#### AWS CLI
```bash
aws rds describe-db-instances  # List RDS instances
aws ecr describe-repositories  # List ECR repos
aws apprunner list-services    # List App Runner services
aws logs tail <log-group>      # Tail logs
```

### B. Migration Checklist

#### Before Starting
- [ ] Read complete assessment document
- [ ] Understand all breaking changes
- [ ] Allocate necessary resources
- [ ] Set up staging environment
- [ ] Create backups
- [ ] Communicate plan to stakeholders

#### During Migration
- [ ] Follow phases in order
- [ ] Test after each major change
- [ ] Document issues and resolutions
- [ ] Keep stakeholders updated
- [ ] Maintain rollback capability

#### After Completion
- [ ] Verify all features working
- [ ] Monitor for 48 hours
- [ ] Update documentation
- [ ] Conduct retrospective
- [ ] Plan next steps

### C. Contact & Support

#### Internal Team
- Lead Developer: [Name]
- DevOps Lead: [Name]
- Project Manager: [Name]

#### External Resources
- Spring Boot Migration Guide: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide
- AWS App Runner Documentation: https://docs.aws.amazon.com/apprunner/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

---

**Document Control**
- **Version:** 1.0
- **Last Updated:** October 22, 2025
- **Next Review:** Upon Phase Completion
- **Owner:** Development Team
