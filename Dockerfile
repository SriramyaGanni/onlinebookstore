# Stage 1: Build WAR using Maven
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests


# Stage 2: Run WAR in Tomcat
FROM tomcat:9.0-jdk17

WORKDIR /usr/local/tomcat/webapps

# Deploy WAR as ROOT application
COPY --from=build /app/target/*.war ROOT.war

EXPOSE 8080

# Tomcat runs automatically
