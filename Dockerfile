FROM eclipse-temurin:25-jdk-noble AS build
WORKDIR /build
COPY backend/.mvn .mvn
COPY backend/mvnw backend/pom.xml ./
RUN chmod +x mvnw
COPY backend/src src
RUN ./mvnw -B -ntp -DskipTests package

FROM eclipse-temurin:25-jre-noble
WORKDIR /app
RUN groupadd --system hotelmanager && useradd --system --gid hotelmanager hotelmanager
COPY --from=build --chown=hotelmanager:hotelmanager /build/target/backend-0.0.1-SNAPSHOT.jar /app/app.jar
USER hotelmanager
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=60 -XX:+UseSerialGC"
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
