FROM ubuntu:18.04

ENV GRADLE_HOME=/opt/gradle/gradle-5.0
ENV PATH=${GRADLE_HOME}/bin:${PATH}

RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    wget \
    unzip && \
    rm -rf /var/lib/apt/lists/*   

RUN wget https://services.gradle.org/distributions/gradle-5.0-bin.zip -P /tmp && \
    unzip -d /opt/gradle /tmp/gradle-*.zip 
 


