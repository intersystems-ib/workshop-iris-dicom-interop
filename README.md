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
Open an interactive session with a *tools* container which contains the [dcm4che](https://github.com/dcm4che/dcm4che) DICOM simulator.
```
docker exec -it tools bash
```

Have a first look at some of the DICOM files we are goint to use in the query/retrieve scenario. Pay attention to some fields like *PatientID*, *StudyInstanceUID*, *TransferSyntaxUID*, etc:
```
./dcmdump /shared/dicom/d1I00001.dcm
```

Initialize a DICOM database in simulator. We will use this database to run queries using DICOM C-FIND commands:
```
./dcmdir -c /shared/DICOMDIR --fs-id SAMPLEDICOMS --fs-desc /shared/dicom/descriptor /shared/dicom
```

Start simulated DICOM archive that uses the previous initialized DICOM database for query/retrieve. This will receive C-FIND and C-MOVE commands:
```
./dcmqrscp --ae-config /shared/ae.properties -b DCM_QRY_SCP:3010 --dicomdir /shared/DICOMDIR
```

Now, open a terminal session in IRIS:
```
docker exec -it iris bash
iris session iris
```

Send a query message and have a look at the [QueryService messages](http://localhost:52773/csp/user/EnsPortal.MessageViewer.zen?SOURCEORTARGET=QueryService). Notice the multiple DICOM responses corresponding to several entries the DICOM archive have found:
```objectscript
do ##class(DICOM.BS.QueryService).TestFind()
```

Send move request, have a look at the [MoveService messages](http://localhost:52773/csp/user/EnsPortal.MessageViewer.zen?SOURCEORTARGET=MoveService). Notice that after the C-MOVE command, the DICOM archive will send the requested documents to the Production through the [DICOM Store In](http://localhost:52773/csp/user/EnsPortal.MessageViewer.zen?SOURCEORTARGET=DICOM%20Store%20In) service.
```objectscript
do ##class(DICOM.BS.MoveService).TestMove()
```