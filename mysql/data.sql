CREATE TABLE WorkList (
    PatientID VARCHAR(20),
    PatientName VARCHAR(100),
    Modality VARCHAR(10),
    ScheduledDate DATE,
    ScheduledTime TIME
);


INSERT INTO WorkList (PatientID, PatientName, Modality, ScheduledDate, ScheduledTime) 
VALUES
('DEMO001', 'Alice Demo', 'CT', '2025-04-04', '08:00:00'),
('DEMO002', 'Bob Demo', 'MR', '2025-04-04', '08:30:00'),
('DEMO003', 'Carol Demo', 'US', '2025-04-04', '09:00:00'),
('P001', 'John Smith', 'CT', CURDATE(), '08:00:00'),
('P002', 'Emily Johnson', 'MR', CURDATE(), '08:30:00'),
('P003', 'Michael Brown', 'US', CURDATE(), '09:00:00'),
('P004', 'Jessica Davis', 'CR', CURDATE(), '09:30:00'),
('P005', 'David Wilson', 'DX', CURDATE(), '10:00:00'),
('P006', 'Sarah Miller', 'CT', CURDATE(), '10:30:00'),
('P007', 'Daniel Garcia', 'MR', CURDATE(), '11:00:00'),
('P008', 'Laura Martinez', 'US', CURDATE(), '11:30:00'),
('P009', 'James Anderson', 'CR', CURDATE(), '12:00:00'),
('P010', 'Olivia Thomas', 'DX', CURDATE(), '12:30:00');
