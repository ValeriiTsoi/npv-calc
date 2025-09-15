FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline || true
COPY src ./src
RUN mvn -q -DskipTests package
FROM eclipse-temurin:17-jre
ENV JAVA_OPTS="-Xms256m -Xmx512m"
WORKDIR /opt/app
COPY --from=build /app/target/npv-calc-0.1.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["sh","-lc","java $JAVA_OPTS -jar app.jar"]
