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

## Receiving DICOM with embedded PDF
Open an interactive session with a *tools* container which contains the [dcm4che](https://github.com/dcm4che/dcm4che) DICOM simulator.
```
docker exec -it tools bash
```

Build a DICOM document with a PDF embedded and some metadata:
```
./pdf2dcm -m PatientName=Simpson^Homer -m PatientSex=M -- /shared/pdf/sample.pdf /shared/pdf/embeddedpdf.dcm
```

Send DICOM document to IRIS Business Service
```
./storescu -b DCM_PDF_SCP -c IRIS_PDF_SCU@iris:2010 /shared/pdf/embeddedpdf.dcm
```

Have a look at the [received messages](http://localhost:52773/csp/user/EnsPortal.MessageViewer.zen)!.

## Query / Retrieve scenario

Initialize a DICOM database in simulator that we can query:
```
./dcmdir -c /shared/DICOMDIR --fs-id SAMPLEDICOMS --fs-desc /shared/dicom/descriptor /shared/dicom
```

Start simulated DICOM archive for query/retrieve:
```
./dcmqrscp --ae-config /shared/ae.properties -b DCM_QRY_SCP:3010 --dicomdir /shared/DICOMDIR
```

Send query message
```objectscript
do ##class(DICOM.BS.QueryService).TestFind()
```

Send move request
```objectscript
do ##class(DICOM.BS.MoveService).TestMove()
```