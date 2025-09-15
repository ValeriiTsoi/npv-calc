# ---------- build ----------
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests clean package

# ---------- runtime ----------
FROM eclipse-temurin:17-jre
ENV JAVA_OPTS=""
WORKDIR /app
COPY --from=build /workspace/target/app.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["sh","-lc","exec java $JAVA_OPTS -jar /app/app.jar"]