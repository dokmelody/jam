FROM openjdk:8-alpine

COPY target/uberjar/dok-jam.jar /dok-jam/app.jar

EXPOSE 3000

CMD ["java", "-jar", "/dok-jam/app.jar"]
