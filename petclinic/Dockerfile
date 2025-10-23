FROM public.ecr.aws/bitnami/java:1.8.422

# Install AWS CLI properly and clean up
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
