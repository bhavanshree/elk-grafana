# Stage 1: Build the application with Maven
FROM maven:3.8.8-eclipse-temurin-17 AS build
WORKDIR /app
ARG SPRING_PROFILES_ACTIVE

ENV SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE}
# Copy the project files
COPY . .

COPY settings.xml /root/.m2/settings.xml

# Build the application
RUN mvn clean package -DskipTests

# Stage 2: Runtime environment
# FROM maven:3.8.1-openjdk-17-slim
WORKDIR /app/target

RUN apt-get update && apt-get install -y tzdata
ENV TZ=Asia/Kolkata

# Copy the built JAR from the build stage
# COPY --from=build /app/target/order-0.0.1-SNAPSHOT.jar order.jar


# Set the entrypoint to run the branch-service jar
# CMD ["java", "-jar", "/app/order.jar"]

CMD ["java", "-jar", "/app/target/order-0.0.1-SNAPSHOT.jar"]