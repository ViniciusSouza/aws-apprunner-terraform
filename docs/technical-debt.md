# Technical Debt Register

**Last Updated:** October 22, 2025  
**Project:** AWS App Runner Terraform - Spring PetClinic  
**Current Status:** Post-Critical Security Fixes (Sprint 1)

---

## Overview

This document tracks technical debt items identified in the [initial code assessment](../initial-code-assessment.md) that are **not** addressed in Sprint 1 (Critical Security Fixes). These items should be planned for future sprints based on priority and capacity.

## Debt Categories

- 🔴 **Critical**: Security risk or EOL component (high priority)
- 🟡 **High**: Performance impact or maintainability issue
- 🟢 **Medium**: Nice-to-have or future-proofing
- ⚪ **Low**: Minor improvements

---

## 1. Application Layer Debt

### 1.1 Java Platform Upgrade
**Status:** 🔴 Critical (after Spring Boot 2.7 stabilizes)  
**Current:** Java 1.8  
**Target:** Java 17 LTS (or Java 21 LTS)  
**Estimated Effort:** Medium (2-3 weeks)

**Why It Matters:**
- Java 8 public updates ended January 2019
- Missing 5+ years of JVM performance improvements
- Missing modern language features (records, pattern matching, text blocks, etc.)
- Required for Spring Boot 3.x migration

**Prerequisites:**
- Sprint 1 completed (Spring Boot 2.7 stable)
- Team training on Java 17 features
- Development environment updates

**Implementation Steps:**
1. Update `java.version` in pom.xml to 17
2. Update Dockerfile base image to Java 17
3. Search and replace `javax.*` → `jakarta.*` (for future Spring Boot 3)
4. Fix any compilation errors
5. Update JVM arguments if needed
6. Test thoroughly

**Risks:**
- Some third-party libraries may not support Java 17
- Build tools may need updates
- Deprecated API usage needs addressing

**Related Files:**
- `petclinic/pom.xml`
- `petclinic/Dockerfile`
- All Java source files (potentially)

**Future Sprint:** Sprint 2 or 3

---

### 1.2 Spring Boot 3.x Migration
**Status:** 🔴 Critical (long-term)  
**Current:** Spring Boot 2.7.18  
**Target:** Spring Boot 3.3.x  
**Estimated Effort:** Large (4-6 weeks)

**Why It Matters:**
- Spring Boot 2.7 support ends November 2025 (< 1 year)
- Spring Boot 3.x is the current major version
- Better performance and modern features
- Required for long-term supportability

**Prerequisites:**
- Java 17 upgrade completed (Task 1.1)
- Spring Boot 2.7 running stable in production
- Team training on Spring Boot 3 migration
- Comprehensive test coverage (≥80%)

**Implementation Steps:**
1. Update to latest Spring Boot 2.7.x first
2. Review Spring Boot 3.0 migration guide
3. Update parent version to 3.3.x
4. Replace all `javax.*` → `jakarta.*`
5. Update Spring Security configuration (if used)
6. Fix Hibernate 6 compatibility issues
7. Update all Spring dependencies
8. Remove deprecated API usage
9. Test extensively

**Breaking Changes:**
- Jakarta EE 9+ package rename (`javax.*` → `jakarta.*`)
- Spring Security configuration changes
- Hibernate 6 (criteria API, type system)
- Property binding changes
- Actuator endpoint changes

**Risks:**
- High risk of breaking changes
- Extensive testing required
- Potential third-party library incompatibilities
- Database query compatibility (Hibernate 6)

**Related Files:**
- `petclinic/pom.xml`
- All `*.java` files with `javax.*` imports
- `src/main/resources/application*.properties`
- Entity classes, repositories, services, controllers

**Future Sprint:** Sprint 4-5 (after Java 17 stabilizes)

---

### 1.3 Frontend Modernization
**Status:** 🟡 High  
**Current:** Bootstrap 3.4.1, jQuery 3.7.1, jQuery UI 1.13.2  
**Target:** Bootstrap 5.x, vanilla JavaScript or modern framework  
**Estimated Effort:** Medium-Large (3-5 weeks)

**Why It Matters:**
- Bootstrap 3.x EOL since July 2019
- Bootstrap 5 has better accessibility, smaller footprint
- Modern CSS features (flexbox, grid)
- Potential to reduce jQuery dependency

**Prerequisites:**
- Sprint 1 completed (jQuery 3.x working)
- UI/UX review and acceptance
- Cross-browser testing plan

**Implementation Steps:**
1. Update Bootstrap webjar to 5.3.x
2. Update all Thymeleaf templates for Bootstrap 5 markup
3. Replace Bootstrap 3 classes (`.col-xs-*`, `.panel`, etc.)
4. Update forms to Bootstrap 5 structure
5. Review and reduce jQuery usage
6. Update CSS customizations
7. Comprehensive visual regression testing

**Breaking Changes:**
- Grid system changes (no `.col-xs-*`)
- Component markup changes (cards replace panels)
- JavaScript changes (Bootstrap 5 requires Popper.js)
- Utility class renames

**Risks:**
- UI/UX regressions
- Time-consuming template updates
- Cross-browser compatibility issues

**Related Files:**
- `petclinic/pom.xml` (webjar versions)
- `src/main/resources/templates/**/*.html` (all templates)
- `src/main/less/**/*.less` (CSS customizations)
- `src/main/wro/wro.xml` (resource processing)

**Future Sprint:** Sprint 3-4 (lower priority than backend upgrades)

---

## 2. Database Layer Debt

### 2.1 MySQL 5.7 → 8.0 Upgrade
**Status:** 🔴 Critical (EOL October 2023)  
**Current:** MySQL 5.7  
**Target:** MySQL 8.0.35+  
**Estimated Effort:** Medium (2-3 weeks including testing)

**Why It Matters:**
- MySQL 5.7 EOL since October 2023 (2 years past EOL)
- No security updates or bug fixes
- MySQL 8.0 has better performance (20-30% in some workloads)
- Modern features (window functions, CTEs, JSON improvements)

**Prerequisites:**
- Application stable on Spring Boot 2.7 or 3.x
- Database backup and restore procedure tested
- Staging environment for testing
- Downtime window approved (if not blue-green)

**Implementation Steps:**
1. Create RDS snapshot backup
2. Review MySQL 8.0 incompatibilities
3. Test queries for compatibility
4. Update terraform/rds.tf engine_version
5. Create new RDS instance (blue-green approach)
6. Migrate data using DMS or mysqldump
7. Update application connection string
8. Cutover with minimal downtime
9. Monitor for 48 hours
10. Decommission old instance

**Breaking Changes:**
- Default authentication plugin changed (caching_sha2_password)
- Some SQL mode changes
- Reserved keywords added
- Character set defaults changed

**Risks:**
- Query compatibility issues
- Application connection issues with new auth
- Downtime during migration (if not blue-green)
- Data integrity during migration

**Related Files:**
- `terraform/rds.tf`
- `terraform/parameters.tf`
- `petclinic/src/main/resources/application-mysql.properties`
- `petclinic/docker-compose.yml`

**Future Sprint:** Sprint 3-4 (coordinate with infrastructure sprint)

---

### 2.2 Database Connection Improvements
**Status:** 🟢 Medium  
**Current:** Direct RDS connection  
**Target:** AWS RDS Proxy  
**Estimated Effort:** Small (1 week)

**Why It Matters:**
- Better connection pooling and management
- Reduced database load during scaling
- Improved failover handling
- IAM authentication support

**Prerequisites:**
- RDS instance running MySQL 8.0
- IAM roles configured

**Implementation Steps:**
1. Create RDS Proxy via Terraform
2. Update security groups
3. Update application connection string
4. Test connection pooling
5. Monitor connection metrics

**Related Files:**
- `terraform/rds.tf` (new RDS Proxy resource)
- `terraform/services.tf` (update connection string)

**Future Sprint:** Sprint 5-6 (optimization phase)

---

## 3. Infrastructure Layer Debt

### 3.1 Terraform Infrastructure Modernization
**Status:** 🟡 High  
**Current:** Terraform 0.12 syntax, no backend, AWS provider unversioned  
**Target:** Terraform 1.5+, S3 backend, AWS provider ~> 5.0  
**Estimated Effort:** Medium (2-3 weeks)

**Why It Matters:**
- Terraform 0.12 unsupported since 2019
- Missing state locking (risk of corruption)
- Missing modern Terraform features
- Team using different Terraform versions (drift risk)

**Prerequisites:**
- Team trained on Terraform 1.x syntax changes
- S3 bucket and DynamoDB table for state backend
- Staging environment for testing

**Implementation Steps:**
1. ✅ Add version constraints (completed in Sprint 1)
2. Create S3 bucket for state storage
3. Create DynamoDB table for state locking
4. Add backend configuration
5. Migrate state: `terraform init -migrate-state`
6. Update resource syntax for Terraform 1.x
7. Update deprecated arguments
8. Test plan and apply in staging
9. Document new workflow

**Terraform 1.x Changes:**
- `version` argument in providers block deprecated
- Count and for_each improvements
- Better error messages
- Improved plan output

**Related Files:**
- `terraform/provider.tf` (backend config)
- `terraform/*.tf` (all files - potential syntax updates)
- New: `terraform/backend.tf`

**Future Sprint:** Sprint 3 (infrastructure modernization sprint)

---

### 3.2 RDS Security Hardening
**Status:** 🔴 Critical (security risk)  
**Current:** Publicly accessible, minimal encryption, no automated backups  
**Target:** Private access, full encryption, automated backups  
**Estimated Effort:** Small (1 week)

**Why It Matters:**
- Publicly accessible database is security risk
- Data should be encrypted at rest
- Backups critical for disaster recovery
- Compliance requirements

**Prerequisites:**
- VPC connector configured for App Runner
- Understanding of network topology

**Implementation Steps:**
1. Create VPC connector for App Runner (or verify existing)
2. Update RDS to `publicly_accessible = false`
3. Enable `storage_encrypted = true`
4. Set `backup_retention_period = 7`
5. Configure backup window
6. Enable CloudWatch log exports
7. Update security groups (remove public ingress)
8. Test App Runner → RDS connectivity
9. Verify backups working

**Related Files:**
- `terraform/rds.tf`
- `terraform/services.tf` (VPC connector)
- `terraform/security-groups.tf`

**Future Sprint:** Sprint 2-3 (high priority security item)

---

### 3.3 Secrets Manager Implementation
**Status:** 🟡 High (security improvement)  
**Current:** SSM Parameter Store, password in entrypoint  
**Target:** AWS Secrets Manager, IAM role-based access  
**Estimated Effort:** Medium (1-2 weeks)

**Why It Matters:**
- Current implementation retrieves password at runtime in shell
- Secrets Manager has automatic rotation
- Better audit logging
- More secure credential management

**Prerequisites:**
- Spring Boot 2.7+ (Spring Cloud AWS support)
- IAM roles configured

**Implementation Steps:**
1. Create secret in Secrets Manager via Terraform
2. Add Spring Cloud AWS Secrets Manager dependency
3. Update application.properties for secrets integration
4. Update IAM role permissions
5. Remove password retrieval from Dockerfile
6. Test secret retrieval
7. Configure secret rotation (optional)

**Related Files:**
- `terraform/secrets.tf` (new file)
- `terraform/iam.tf` (update policies)
- `petclinic/pom.xml` (add dependency)
- `petclinic/src/main/resources/application.properties`
- `petclinic/Dockerfile` (simplify entrypoint)

**Future Sprint:** Sprint 4 (security hardening sprint)

---

## 4. Container & Deployment Debt

### 4.1 Multi-Stage Docker Build
**Status:** 🟡 High  
**Current:** Single-stage, large image, includes build tools  
**Target:** Multi-stage build, optimized image size  
**Estimated Effort:** Small (2-3 days)

**Why It Matters:**
- Faster deployments (smaller image)
- Reduced attack surface (no build tools in runtime)
- Better layer caching
- Industry best practice

**Prerequisites:**
- Application building successfully

**Implementation Steps:**
1. Create multi-stage Dockerfile
2. Stage 1: Maven build
3. Stage 2: Runtime (copy JAR only)
4. Optimize layer caching (copy pom.xml first)
5. Test build and run
6. Compare image sizes
7. Update CI/CD pipeline if needed

**Benefits:**
- Image size reduction: ~500MB → ~200MB (estimated)
- Faster pulls and deployments
- More secure

**Related Files:**
- `petclinic/Dockerfile`

**Future Sprint:** Sprint 3 (infrastructure sprint)

---

### 4.2 Docker Image Optimization
**Status:** 🟢 Medium  
**Current:** Bitnami Java base, apt-based AWS CLI install  
**Target:** Distroless or Alpine base, optimized AWS CLI  
**Estimated Effort:** Small (1 week)

**Why It Matters:**
- Smaller image size
- Fewer vulnerabilities (smaller attack surface)
- Faster deployments

**Prerequisites:**
- Multi-stage build implemented (Task 4.1)

**Implementation Steps:**
1. Evaluate base images (distroless, Alpine, Amazon Corretto)
2. Update Dockerfile with chosen base
3. Install AWS CLI v2 properly
4. Test application startup
5. Security scan new image
6. Compare sizes and vulnerabilities

**Potential Base Images:**
- `public.ecr.aws/amazoncorretto/amazoncorretto:17-alpine`
- `gcr.io/distroless/java17-debian11`
- `eclipse-temurin:17-jre-alpine`

**Related Files:**
- `petclinic/Dockerfile`

**Future Sprint:** Sprint 5-6 (optimization phase)

---

### 4.3 Health Check Implementation
**Status:** 🟡 High  
**Current:** Basic App Runner health check  
**Target:** Comprehensive health checks (liveness, readiness)  
**Estimated Effort:** Small (2-3 days)

**Why It Matters:**
- Better container orchestration
- Faster failure detection
- Improved availability

**Prerequisites:**
- Spring Boot Actuator enabled (already present)

**Implementation Steps:**
1. Add HEALTHCHECK to Dockerfile
2. Configure App Runner health check properly
3. Implement custom health indicators if needed
4. Test health check behavior
5. Monitor in staging

**Related Files:**
- `petclinic/Dockerfile`
- `terraform/services.tf`
- `petclinic/src/main/java/.../health/` (optional custom indicators)

**Future Sprint:** Sprint 3

---

## 5. CI/CD Pipeline Debt

### 5.1 CodePipeline Improvements
**Status:** 🟢 Medium  
**Current:** Basic build → deploy pipeline  
**Target:** Multi-stage pipeline with testing, approvals  
**Estimated Effort:** Medium (2 weeks)

**Why It Matters:**
- Automated testing before deployment
- Manual approval gates for production
- Better deployment visibility
- Reduced deployment risks

**Prerequisites:**
- Comprehensive test suite
- Staging environment

**Implementation Steps:**
1. Add testing stage to pipeline
2. Add manual approval stage
3. Add SNS notifications
4. Implement blue-green deployment
5. Add rollback capability
6. Document new pipeline

**Related Files:**
- `terraform/codepipeline.tf`
- New: `terraform/sns.tf` (notifications)

**Future Sprint:** Sprint 5-6

---

### 5.2 CodeBuild Optimization
**Status:** 🟢 Medium  
**Current:** Basic build, no caching  
**Target:** Optimized build with Maven caching  
**Estimated Effort:** Small (1 week)

**Why It Matters:**
- Faster builds (cache Maven dependencies)
- Reduced costs
- Better developer experience

**Prerequisites:**
- S3 bucket for build cache

**Implementation Steps:**
1. Create S3 bucket for cache
2. Update buildspec.yml with cache configuration
3. Update IAM permissions
4. Test build times
5. Monitor cache hit rate

**Related Files:**
- `terraform/codebuild.tf`
- `buildspec.yml` (if exists, or create)

**Future Sprint:** Sprint 5-6

---

## 6. Security Hardening Debt

### 6.1 IAM Role Least Privilege
**Status:** 🟡 High  
**Current:** Broad IAM permissions  
**Target:** Minimal required permissions  
**Estimated Effort:** Medium (1-2 weeks)

**Why It Matters:**
- Security best practice
- Compliance requirements
- Reduced blast radius of compromises

**Prerequisites:**
- Understanding of all AWS services used
- Testing environment

**Implementation Steps:**
1. Audit current IAM permissions
2. Document required actions per role
3. Create restrictive policies
4. Test in staging
5. Apply to production
6. Monitor for permission errors

**Related Files:**
- `terraform/iam.tf`
- All IAM policy documents

**Future Sprint:** Sprint 4 (security sprint)

---

### 6.2 Enable AWS WAF
**Status:** 🟢 Medium  
**Current:** No WAF  
**Target:** WAF with basic rules  
**Estimated Effort:** Small (1 week)

**Why It Matters:**
- Protection against common attacks (SQL injection, XSS)
- Rate limiting
- Geographic filtering if needed
- Compliance requirements

**Prerequisites:**
- App Runner service deployed

**Implementation Steps:**
1. Create WAF WebACL
2. Add managed rule groups
3. Associate with App Runner
4. Configure CloudWatch metrics
5. Test and tune rules

**Related Files:**
- New: `terraform/waf.tf`

**Future Sprint:** Sprint 6 (security hardening)

---

### 6.3 Enable CloudWatch Insights
**Status:** 🟢 Medium  
**Current:** Basic CloudWatch Logs  
**Target:** Application Insights, X-Ray tracing  
**Estimated Effort:** Small (1 week)

**Why It Matters:**
- Better observability
- Performance monitoring
- Debugging production issues
- Cost optimization insights

**Prerequisites:**
- Application deployed

**Implementation Steps:**
1. Enable X-Ray in App Runner
2. Add X-Ray SDK to application
3. Configure Application Insights
4. Create CloudWatch dashboards
5. Set up alarms

**Related Files:**
- `petclinic/pom.xml` (X-Ray SDK)
- `terraform/services.tf` (observability config)
- New: `terraform/cloudwatch.tf`

**Future Sprint:** Sprint 5-6

---

## 7. Code Quality & Maintainability

### 7.1 Increase Test Coverage
**Status:** 🟡 High  
**Current:** Unknown (need to measure)  
**Target:** ≥80% code coverage  
**Estimated Effort:** Medium-Large (3-4 weeks)

**Why It Matters:**
- Confidence in refactoring
- Catch regressions early
- Better code quality
- Required for major version upgrades

**Prerequisites:**
- JaCoCo configured (already present)

**Implementation Steps:**
1. Measure current coverage
2. Identify gaps
3. Write missing unit tests
4. Write integration tests
5. Add coverage gates to CI/CD
6. Document testing standards

**Related Files:**
- `petclinic/src/test/java/**/*` (test files)

**Future Sprint:** Ongoing (Sprint 2-6)

---

### 7.2 Remove Circular Dependencies
**Status:** 🟢 Medium  
**Current:** Circular dependencies allowed in config  
**Target:** No circular dependencies  
**Estimated Effort:** Medium (2-3 weeks)

**Why It Matters:**
- Better architecture
- Easier testing
- Spring Boot 3 discourages circular dependencies
- Code maintainability

**Prerequisites:**
- Understanding of current architecture

**Implementation Steps:**
1. Identify circular dependencies
2. Refactor code to break cycles
3. Use events or interfaces
4. Remove `allow-circular-references=true`
5. Test thoroughly

**Related Files:**
- Various service and component classes
- `application.properties`

**Future Sprint:** Sprint 4-5 (before Spring Boot 3)

---

### 7.3 Code Documentation
**Status:** 🟢 Medium  
**Current:** Minimal JavaDoc  
**Target:** Comprehensive JavaDoc on public APIs  
**Estimated Effort:** Medium (ongoing)

**Why It Matters:**
- Easier onboarding
- Better IDE support
- Code maintainability

**Prerequisites:**
- Coding standards defined

**Implementation Steps:**
1. Define JavaDoc standards
2. Add JavaDoc to public classes/methods
3. Generate JavaDoc site
4. Add to CI/CD pipeline
5. Publish documentation

**Related Files:**
- All Java source files
- `pom.xml` (maven-javadoc-plugin)

**Future Sprint:** Ongoing (Sprint 3-6)

---

## 8. Performance Optimization

### 8.1 JVM Tuning
**Status:** 🟢 Medium  
**Current:** Default JVM settings  
**Target:** Optimized for container environment  
**Estimated Effort:** Small (1 week)

**Why It Matters:**
- Better memory utilization
- Faster startup
- Improved throughput
- Cost optimization

**Prerequisites:**
- Application running in containers
- Performance baseline

**Implementation Steps:**
1. Profile application memory usage
2. Set appropriate heap size
3. Enable container support flags
4. Configure GC settings
5. Monitor and tune

**Example JVM Flags:**
```
-XX:+UseContainerSupport
-XX:MaxRAMPercentage=75.0
-XX:+UseG1GC
```

**Related Files:**
- `petclinic/Dockerfile`
- `terraform/services.tf` (environment variables)

**Future Sprint:** Sprint 5-6

---

### 8.2 Database Query Optimization
**Status:** 🟢 Medium  
**Current:** Unknown performance  
**Target:** Optimized queries with proper indexing  
**Estimated Effort:** Medium (2-3 weeks)

**Why It Matters:**
- Faster response times
- Reduced database load
- Better user experience

**Prerequisites:**
- MySQL slow query log enabled
- Performance testing tools

**Implementation Steps:**
1. Enable slow query logging
2. Identify slow queries
3. Add missing indexes
4. Optimize N+1 queries
5. Add query caching where appropriate
6. Load test

**Related Files:**
- `petclinic/src/main/resources/db/mysql/schema.sql`
- Repository classes (add fetch strategies)

**Future Sprint:** Sprint 6

---

## Sprint Planning Suggestions

### Recommended Sprint Order

**Sprint 1: Critical Security Fixes** ✅ (Current)
- jQuery, Spring Boot 2.7, Terraform provider, Docker security
- Estimated: 2 weeks
- Status: In Progress

**Sprint 2: Foundation Stability**
- RDS security hardening (3.2)
- Increase test coverage (7.1)
- Health check implementation (4.3)
- Estimated: 3 weeks

**Sprint 3: Infrastructure Modernization**
- Terraform backend and modernization (3.1)
- Multi-stage Docker build (4.1)
- Docker image optimization (4.2)
- Estimated: 3 weeks

**Sprint 4: Java 17 Migration**
- Java 8 → Java 17 upgrade (1.1)
- Remove circular dependencies (7.2)
- IAM least privilege (6.1)
- Secrets Manager (3.3)
- Estimated: 4 weeks

**Sprint 5: Spring Boot 3 Migration**
- Spring Boot 2.7 → 3.3 upgrade (1.2)
- Frontend modernization (1.3)
- JVM tuning (8.1)
- Estimated: 5-6 weeks

**Sprint 6: Database & Optimization**
- MySQL 5.7 → 8.0 upgrade (2.1)
- RDS Proxy (2.2)
- Database query optimization (8.2)
- CloudWatch Insights (6.3)
- Estimated: 3-4 weeks

**Sprint 7: CI/CD & Final Polish**
- CodePipeline improvements (5.1)
- CodeBuild optimization (5.2)
- WAF implementation (6.2)
- Documentation (7.3)
- Estimated: 2-3 weeks

**Total Timeline:** 22-32 weeks (5.5-8 months)

---

## Priority Matrix

| Priority | Security | Performance | Maintainability | Effort |
|----------|----------|-------------|-----------------|--------|
| 🔴 **Now** (Sprint 1-2) | RDS Security (3.2) | Test Coverage (7.1) | - | Various |
| 🟡 **Next** (Sprint 3-4) | Secrets Mgr (3.3), IAM (6.1) | - | Terraform (3.1), Java 17 (1.1) | Medium-Large |
| 🟢 **Later** (Sprint 5-6) | WAF (6.2) | MySQL 8 (2.1), JVM (8.1) | Spring Boot 3 (1.2) | Large |
| ⚪ **Nice to Have** (Sprint 7+) | - | Query Opt (8.2), RDS Proxy (2.2) | Docs (7.3), Frontend (1.3) | Medium |

---

## Metrics to Track

### Security Metrics
- Number of critical/high vulnerabilities (target: 0)
- Number of EOL components (target: 0)
- Days since last security patch (target: <30)
- IAM policies meeting least privilege (target: 100%)

### Performance Metrics
- Application startup time
- Response time (p50, p95, p99)
- Memory utilization
- Database query performance

### Quality Metrics
- Code coverage percentage (target: ≥80%)
- Number of circular dependencies (target: 0)
- JavaDoc coverage (target: ≥70% public APIs)
- Technical debt ratio (SonarQube)

### Operational Metrics
- Deployment frequency
- Mean time to recovery (MTTR)
- Change failure rate
- Pipeline execution time

---

## Decision Log

### Why Not Upgrade Everything at Once?
**Decision:** Phased approach over big-bang  
**Rationale:**
- Lower risk per sprint
- Easier rollback if issues arise
- Team can learn incrementally
- Maintains production stability
- Allows time for thorough testing

### Why Java 17 Instead of Java 21?
**Decision:** Target Java 17 LTS first  
**Rationale:**
- Java 17 is minimum for Spring Boot 3
- Proven stability (released Sep 2021)
- Wider ecosystem support
- Can upgrade to Java 21 later if needed

### Why Spring Boot 2.7 Before 3.x?
**Decision:** Intermediate step to 2.7  
**Rationale:**
- Reduces migration risk
- Spring Boot 2.7 is LTS (supported until Nov 2025)
- Allows time to prepare for 3.x breaking changes
- Provides immediate security value

### Why MySQL 8.0 in Later Sprint?
**Decision:** Defer to Sprint 6  
**Rationale:**
- Application-layer upgrades higher priority
- MySQL 5.7 EOL but not immediate risk if network secured
- Database migration requires careful planning
- Blue-green deployment takes time to set up

---

## Notes

- This document should be reviewed quarterly and updated as items are completed
- Each debt item can become a detailed implementation plan when scheduled
- Some items may be combined or split based on actual sprint capacity
- Priority may shift based on business needs or new vulnerabilities

**Next Review Date:** January 22, 2026 (or after Sprint 1 completion)
