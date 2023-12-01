FROM openjdk:8

RUN apt-get update && \
    apt-get install build-essential maven default-jdk cowsay netcat -y && \
    update-alternatives --config javac
COPY . .
WORKDIR /app/
CMD ["mvn", "spring-boot:run"]
