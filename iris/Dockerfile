ARG IMAGE=containers.intersystems.com/intersystems/irishealth-community:latest-em
FROM $IMAGE

USER ${ISC_PACKAGE_MGRUSER}

COPY --chown=$ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP irissession.sh /
RUN chmod +x /irissession.sh

# copy files
COPY --chown=$ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP src /tmp/src

SHELL ["/irissession.sh"]

RUN \
  zn "USER" \
  # create credentials
  do ##class(Ens.Config.Credentials).SetCredential("MySQL_User","testuser","testpassword") \
  # load & compile source code
  do $SYSTEM.OBJ.LoadDir("/tmp/src", "ck", , 1) \
  # start production
  set production = "DICOM.Production" \
  set ^Ens.Configuration("csp","LastProduction") = production \
  do ##class(Ens.Director).SetAutoStart(production) \
  set sc = 1

# bringing the standard shell back
SHELL ["/bin/bash", "-c"]