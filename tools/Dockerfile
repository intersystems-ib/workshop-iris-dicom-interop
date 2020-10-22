FROM openjdk:8

RUN apt-get update && apt-get install -y wget

WORKDIR /tmp

# download dcm4che simulator binaries
# https://github.com/dcm4che/dcm4che
RUN wget https://master.dl.sourceforge.net/project/dcm4che/dcm4che3/5.22.6/dcm4che-5.22.6-bin.zip
RUN unzip dcm4che-5.22.6-bin.zip

WORKDIR /tmp/dcm4che-5.22.6/bin

CMD while sleep 3600; do :; done