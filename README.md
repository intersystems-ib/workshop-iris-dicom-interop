Simple DICOM integration using IRIS for Health

# Setup
Build the images and run the containers:
```
docker-compose build
docker-compose up -d
```

# Usage

## IRIS Production
Open [DICOM.Production](http://localhost:52773/csp/user/EnsPortal.ProductionConfig.zen?PRODUCTION=DICOM.Production&$NAMESPACE=USER). Use the default `superuser` / `SYS` account.

## Simulate some messages
Open an interactive session with a *tools* container which contains the [dcm4che](https://github.com/dcm4che/dcm4che) DICOM simulator.

```
docker exec -it tools sh
```

Build a DICOM document with a PDF embedded and some metadata:
```
./pdf2dcm -m PatientName=Simpson^Homer -m PatientSex=M -- /shared/pdi.pdf /shared/object.dcm
```

Send DICOM document to IRIS Business Service
```
./storescu -b URO -c IRIS-URO@iris:22026 /shared/object.dcm
```

Have a look at the [received messages](http://localhost:52773/csp/user/EnsPortal.MessageViewer.zen)!.