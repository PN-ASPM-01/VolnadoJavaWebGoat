ARG BASE_FINAL_IMAGE=700386920060.dkr.ecr.us-east-1.amazonaws.com/cbc/cbc-fips-eclipse-temurin:20231130-1255


######## Build ########
FROM maven:3.8.4-eclipse-temurin-17 AS build

ARG PROJECT_KEY
ARG SONAR_HOST
ARG SONAR_LOGIN

WORKDIR /src
# this copy uses the .dockerignore to only copy src .m2 and pom.xml
COPY . /src/

# LOG_DIR is needed because the plugins are writing log files 
ENV LOG_DIR=/tmp/logs/
ENV LOG_LEVEL=INFO

# Maven deploy
# RUN mvn -e -s .m2/settings.xml clean deploy sonar:sonar \
#                 -Dsonar.projectKey=${PROJECT_KEY} \
#                 -Dsonar.host.url=${SONAR_HOST} \
#                 -Dsonar.login=${SONAR_LOGIN}

#Maven Build

RUN apt-get update && \
    apt-get install build-essential maven default-jdk cowsay netcat -y && \
    update-alternatives --config javac
COPY . .

CMD ["mvn", "spring-boot:run"]

######## Dependencies ########
FROM alpine:3.16 as deps

WORKDIR /app/

# update packages and install
RUN echo "===> OS Update..." \
    && DEBIAN_FRONTEND=noninteractive apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq procps ca-certificates

# userid and groupid to run as
ARG UID=1000
ARG GID=1000

# create non-priv user and group and set homedir as /tmp
RUN groupadd -g "${GID}" non-priv \
  && useradd --create-home -d /tmp --no-log-init -u "${UID}" -g "${GID}" non-priv
# create tmp-pre-boot folder to allow copying into /tmp on bootup and fix permissions
# before changing user (but user must have been created already)
RUN mkdir /tmp-pre-boot || true && chown -R non-priv:non-priv /tmp-pre-boot
USER non-priv

COPY --chown=${UID}:${GID} --from=build /src/target/vulnado.jar /app/vulnado.jar

# LOG_DIR is needed because the plugins are writing log files
ENV LOG_DIR=/tmp/logs/
ENV LOG_LEVEL=ERROR
