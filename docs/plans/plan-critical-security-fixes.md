---
goal: "Critical Security Fixes - Address EOL Dependencies"
status: in-progress
created: 2025-10-22
started: 2025-10-22
estimated_effort: medium
sprint: 1
delegate_to_agent: true
agent_tasks: 4
tasks_total: 14
tasks_completed: 0
agent_tasks_completed: 0
---

# Implementation Plan: Critical Security Fixes

## 🎯 Objective

Address the most critical security vulnerabilities and EOL components with minimal breaking changes:
1. Update jQuery 2.2.4 → 3.7.1 (fixes CVE-2015-9251, CVE-2020-11022, CVE-2020-11023)
2. Upgrade Spring Boot 2.3.3 → 2.7.18 (LTS, receives updates until Nov 2025)
3. Update frontend dependencies (Bootstrap, jQuery UI)
4. Fix Terraform provider configuration
5. Improve Docker security (specific version tags, non-root user)

This provides immediate security value while avoiding the high-risk Spring Boot 3.x migration.

## 📋 Prerequisites

- [x] Code assessment completed
- [ ] Development environment set up (Java 8, Maven 3.6+)
- [ ] Local MySQL 5.7 instance for testing
- [ ] Access to staging environment
- [ ] Backup of current production deployment

## 🔧 Implementation Tasks

### Phase 1: Frontend Security Updates (Low Risk)

1. [ ] **Update jQuery and related dependencies**
   - Files: `petclinic/pom.xml`
   - Details: Update webjars versions for jQuery, jQuery UI, Bootstrap
   - Risk: Medium - May require template adjustments
   - Agent: No

2. [ ] **Audit and update Thymeleaf templates**
   - Files: `petclinic/src/main/resources/templates/**/*.html`
   - Details: Test all interactive elements with new jQuery, fix any breaking changes
   - Risk: Low - Mostly backward compatible
   - Agent: No

3. [ ] **Update wro4j configuration**
   - Files: `petclinic/pom.xml`
   - Details: Update wro4j-maven-plugin to 1.10.1
   - Risk: Low
   - Agent: No

### Phase 2: Spring Boot Incremental Upgrade (Medium Risk)

4. [ ] **Upgrade Spring Boot to 2.7.18**
   - Files: `petclinic/pom.xml`
   - Details: Update parent version, review release notes
   - Risk: Medium - Some configuration changes needed
   - Agent: No

5. [ ] **Update application.properties for Spring Boot 2.7**
   - Files: `petclinic/src/main/resources/application.properties`, `petclinic/src/main/resources/application-mysql.properties`
   - Details: Replace deprecated `spring.datasource.initialization-mode` with `spring.sql.init.mode`
   - Risk: Low
   - Agent: No

6. [ ] **Update Maven plugins**
   - Files: `petclinic/pom.xml`
   - Details: Update checkstyle (3.3.1), checkstyle dependency (10.12.4), jacoco (0.8.12)
   - Risk: Low
   - Agent: No

7. [ ] **Fix circular dependency warnings**
   - Files: `petclinic/src/main/resources/application.properties`
   - Details: Temporarily add `spring.main.allow-circular-references=true`, document for future refactoring
   - Risk: Low
   - Agent: No

### Phase 3: Infrastructure Quick Wins (Low Risk)

8. [ ] **Update Terraform provider configuration**
   - Files: `terraform/provider.tf`
   - Details: Add required_version >= 1.5, add required_providers block with AWS ~> 5.0
   - Risk: Low - No infrastructure changes, just version constraints
   - Agent: No

9. [ ] **Optimize Dockerfile for security**
   - Files: `petclinic/Dockerfile`
   - Details: Use specific Java version tag, add non-root user, clean up apt cache
   - Risk: Low
   - Agent: No

10. [ ] **Update docker-compose.yml**
    - Files: `petclinic/docker-compose.yml`
    - Details: Add version, health checks, use environment variables for passwords
    - Risk: Low
    - Agent: No

11. [ ] **Create .dockerignore**
    - Files: `petclinic/.dockerignore`
    - Details: Exclude unnecessary files from Docker build context
    - Risk: None
    - Agent: Yes

### Phase 4: Testing & Validation

12. [ ] **Run full test suite**
    - Details: `mvn clean test`, ensure all tests pass
    - Risk: None
    - Agent: No

13. [ ] **Build and test Docker image**
    - Details: Build locally, test with docker-compose
    - Risk: Low
    - Agent: No

14. [ ] **Deploy to staging environment**
    - Details: Full deployment test in staging
    - Risk: Low
    - Agent: No

## 🤖 GitHub Copilot Agent Tasks

Tasks that can be delegated to GitHub Copilot Agent for parallel execution:

1. [ ] **Create .dockerignore file**
   - Type: configuration
   - Files: `petclinic/.dockerignore`
   - Instructions: Create .dockerignore with common exclusions (.git, target/, *.md, .github/, terraform/, docs/, plan/)
   - Dependencies: None

2. [ ] **Update integration tests for Spring Boot 2.7**
   - Type: integration-tests
   - Files: `petclinic/src/test/java/**/*Tests.java`
   - Instructions: Review and update test configurations if needed for Spring Boot 2.7 compatibility
   - Dependencies: Task 4 (Spring Boot upgrade)

3. [ ] **Generate test coverage report analysis**
   - Type: documentation
   - Files: `docs/test-coverage-report.md`
   - Instructions: After running `mvn jacoco:report`, analyze coverage and document areas needing improvement
   - Dependencies: Task 12 (test suite run)

4. [ ] **Create runbook for new deployment process**
   - Type: documentation
   - Files: `docs/deployment-runbook.md`
   - Instructions: Document step-by-step deployment process with new Docker configuration
   - Dependencies: Task 13 (Docker testing)

## 📁 Files to Modify/Create

### Modified Files
- `petclinic/pom.xml` - Update Spring Boot parent, dependencies, plugins
- `petclinic/src/main/resources/application.properties` - Update deprecated properties
- `petclinic/src/main/resources/application-mysql.properties` - Update database config
- `petclinic/Dockerfile` - Security improvements
- `petclinic/docker-compose.yml` - Add version, health checks
- `terraform/provider.tf` - Add version constraints
- `petclinic/src/main/resources/templates/**/*.html` - Potential jQuery fixes (if needed)

### New Files
- `petclinic/.dockerignore` - Docker build optimization
- `docs/deployment-runbook.md` - Deployment documentation (agent task)
- `docs/test-coverage-report.md` - Test analysis (agent task)

## 🧪 Testing Strategy

### 1. Unit Tests
```bash
cd petclinic
mvn clean test
```
**Expected:** All tests pass

### 2. Integration Tests
```bash
mvn verify
```
**Expected:** Application starts, connects to database, all features work

### 3. Local Docker Testing
```bash
cd petclinic
docker-compose up --build
# Visit http://localhost:8080
# Test: Create owner, add pet, schedule visit
docker-compose down
```

### 4. Frontend Testing
- Test all pages load correctly
- Test all forms work (create/update owner, pet, visit)
- Test JavaScript functionality (form validation, UI interactions)
- Cross-browser testing (Chrome, Firefox, Safari, Edge)

### 5. Security Validation
```bash
# Check for known vulnerabilities
mvn org.owasp:dependency-check-maven:check

# Review dependency-check-report.html
```
**Expected:** Zero critical/high vulnerabilities in frontend libraries

### 6. Staging Deployment
- Deploy to staging environment
- Smoke test all features
- Monitor logs for errors/warnings
- Performance baseline comparison

## ⚠️ Risks & Considerations

### Medium Risks
1. **jQuery 2.x → 3.x Migration**
   - **Risk:** Some jQuery APIs changed between versions
   - **Mitigation:** Test all interactive elements thoroughly, check browser console for errors
   - **Rollback:** Revert pom.xml changes

2. **Spring Boot 2.3 → 2.7**
   - **Risk:** Some configuration properties deprecated
   - **Mitigation:** Follow Spring Boot 2.7 migration guide, test thoroughly
   - **Rollback:** Git revert to previous version

### Low Risks
3. **Terraform Version Constraints**
   - **Risk:** Team may be using older Terraform versions
   - **Mitigation:** Document required Terraform version, provide upgrade instructions
   - **Rollback:** Comment out version constraints

4. **Docker Security Changes**
   - **Risk:** Non-root user may cause permission issues
   - **Mitigation:** Test thoroughly in staging
   - **Rollback:** Revert Dockerfile changes

## ✅ Acceptance Criteria

- [ ] Spring Boot upgraded to 2.7.18 (verified in pom.xml and runtime)
- [ ] jQuery upgraded to 3.7.1 (no console errors)
- [ ] Bootstrap updated to latest 3.x version or 5.x (with template updates)
- [ ] All unit tests pass (`mvn test`)
- [ ] All integration tests pass (`mvn verify`)
- [ ] Application runs successfully with docker-compose
- [ ] OWASP dependency check shows zero critical/high vulnerabilities in updated libraries
- [ ] Terraform configuration includes version constraints
- [ ] Docker image uses specific version tag (not 'latest')
- [ ] Docker container runs as non-root user
- [ ] All interactive features work in staging environment
- [ ] Code formatted with `mvn spring-javaformat:apply`
- [ ] Documentation updated (deployment runbook created)
- [ ] All agent tasks completed

## 🔄 Dependencies

**External Dependencies:**
- MySQL 5.7 (remains unchanged for now)
- AWS infrastructure (no changes in this sprint)

**Task Dependencies:**
- Tasks 2, 12, 13, 14 depend on Task 1 (frontend updates)
- Tasks 5, 6, 7 depend on Task 4 (Spring Boot upgrade)
- Agent Task 2 depends on Task 4
- Agent Tasks 3, 4 depend on Task 12

## 📝 Implementation Details

### Task 1: Update jQuery and Dependencies

**pom.xml changes:**
```xml
<properties>
    <!-- Frontend dependencies -->
    <webjars-bootstrap.version>3.4.1</webjars-bootstrap.version>
    <webjars-jquery-ui.version>1.13.2</webjars-jquery-ui.version>
    <webjars-jquery.version>3.7.1</webjars-jquery.version>
    <wro4j.version>1.10.1</wro4j.version>
    
    <!-- Keep these updated -->
    <jacoco.version>0.8.12</jacoco.version>
    <spring-format.version>0.0.41</spring-format.version>
</properties>
```

**jQuery 3.x Breaking Changes to Watch:**
- `.size()` removed → use `.length`
- `.bind()`, `.unbind()`, `.delegate()` removed → use `.on()`, `.off()`
- AJAX error callbacks changed
- Some selector behaviors changed

### Task 4: Spring Boot 2.3.3 → 2.7.18

**pom.xml changes:**
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.7.18</version>
</parent>
```

**Spring Boot 2.7 Key Changes:**
- `spring.datasource.initialization-mode` → `spring.sql.init.mode`
- Circular references detected by default (need to allow temporarily)
- Some actuator endpoints path changes
- Hibernate 5.6 (minor changes from 5.4)

### Task 6: Update Maven Plugins

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
        <!-- ... -->
    </dependencies>
</plugin>
```

### Task 8: Terraform Provider Configuration

**terraform/provider.tf:**
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
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
```

### Task 9: Dockerfile Security Improvements

```dockerfile
FROM public.ecr.aws/bitnami/java:1.8.422

# Install AWS CLI properly
RUN apt-get update && \
    apt-get -y install awscli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r spring && useradd -r -g spring spring

WORKDIR /app

# Copy application
ADD target/spring-petclinic-2.3.0.jar app.jar

# Change ownership
RUN chown -R spring:spring /app

# Switch to non-root user
USER spring

EXPOSE 80

# Keep existing SSM parameter retrieval (for now)
ENTRYPOINT env spring.datasource.password=$(aws ssm get-parameter --name /database/password --with-decrypt --region $AWS_REGION | grep Value | cut -d '"' -f4) java -Djava.security.egd=file:/dev/./urandom -jar /app.jar
```

### Task 10: Docker Compose Improvements

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:5.7
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-petclinic}
      - MYSQL_ALLOW_EMPTY_PASSWORD=${MYSQL_ALLOW_EMPTY_PASSWORD:-true}
      - MYSQL_USER=${MYSQL_USER:-petclinic}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD:-petclinic}
      - MYSQL_DATABASE=${MYSQL_DATABASE:-petclinic}
    volumes:
      - "./conf.d:/etc/mysql/conf.d:ro"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
```

## 📊 Success Metrics

### Security Improvements
- **Before:** 3 critical CVEs in jQuery 2.2.4
- **After:** 0 critical CVEs in jQuery 3.7.1

### Support Status
- **Before:** Spring Boot 2.3.3 EOL (Nov 2021) - 4 years unsupported
- **After:** Spring Boot 2.7.18 LTS - Supported until Nov 2025

### Dependency Health
- **Before:** Multiple outdated dependencies with known vulnerabilities
- **After:** All frontend dependencies on latest secure versions

## 🔜 Next Steps (Technical Debt)

After this sprint, the following items remain (see technical-debt.md):
1. Java 8 → Java 17 upgrade
2. Spring Boot 2.7 → Spring Boot 3.3 upgrade
3. MySQL 5.7 → MySQL 8.0 upgrade
4. Complete Terraform infrastructure modernization
5. Docker multi-stage builds
6. Secrets Manager implementation
7. Full security hardening

---

## 📚 References

- [Spring Boot 2.7 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.7-Release-Notes)
- [jQuery 3.x Migration Guide](https://jquery.com/upgrade-guide/3.0/)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)
- [Terraform AWS Provider v5](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
