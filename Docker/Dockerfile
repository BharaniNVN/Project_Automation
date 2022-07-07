FROM gradle:6.8.3-jdk8 as build

COPY --chown=gradle:gradle . /home/gradle/src

WORKDIR /home/gradle/src
RUN gradle build --no-daemon

FROM mcr.microsoft.com/java/jdk:8-zulu-ubuntu

RUN apt-get update -y && apt-get upgrade -y

RUN mkdir /app && groupadd -r wvdgroup && useradd -r -g wvdgroup wvduser && chown wvduser:wvdgroup /app

USER wvduser

COPY --from=build /home/gradle/src/build/libs/wvd-provisioning-0.0.1-SNAPSHOT.jar /app/app.jar

# Run the Application
WORKDIR /app

CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar", "--spring.config.location=file:///app/config/application.properties"]
