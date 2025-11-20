FROM amazoncorretto:17

RUN yum install -y wget unzip

WORKDIR /tmp

# download dcm4che simulator binaries
# https://github.com/dcm4che/dcm4che

RUN wget https://sourceforge.net/projects/dcm4che/files/dcm4che3/5.34.1/dcm4che-5.34.1-bin.zip/download -O dcm4che-5.34.1-bin.zip
RUN unzip dcm4che-5.34.1-bin.zip
WORKDIR /tmp/dcm4che-5.34.1/bin

CMD while sleep 3600; do :; done