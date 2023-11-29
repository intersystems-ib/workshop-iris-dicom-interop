FROM amazoncorretto:8

RUN yum install -y wget unzip

WORKDIR /tmp

# download dcm4che simulator binaries
# https://github.com/dcm4che/dcm4che
RUN wget https://master.dl.sourceforge.net/project/dcm4che/dcm4che3/5.22.6/dcm4che-5.22.6-bin.zip
RUN unzip dcm4che-5.22.6-bin.zip

WORKDIR /tmp/dcm4che-5.22.6/bin

CMD while sleep 3600; do :; done