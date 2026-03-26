FROM public.ecr.aws/amazoncorretto/amazoncorretto:21-al2023 AS build
WORKDIR /app
RUN yum install -y maven
COPY pom.xml .
COPY src ./src
RUN mvn -B clean package -DskipTests

FROM public.ecr.aws/amazoncorretto/amazoncorretto:21-al2023
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
