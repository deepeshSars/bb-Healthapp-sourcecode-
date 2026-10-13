# Multi-stage build for register service
FROM maven:3.8.6-eclipse-temurin-11 AS build
WORKDIR /app

# Copy source code
COPY . .

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:11-jre
WORKDIR /app

# Copy the JAR file from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
