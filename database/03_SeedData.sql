-- ============================================================
-- Script 03: Seed Data
-- Employee Management System
-- ============================================================

USE EmployeeManagementDB;
GO

SET IDENTITY_INSERT Departments ON;
INSERT INTO Departments (DepartmentId, DepartmentName, DepartmentCode, Description)
VALUES
    (1, 'Information Technology', 'I', 'Handles all IT infrastructure, software development, and technical support.'),
    (2, 'Human Resources',        'H', 'Manages employee relations, recruitment, and organizational development.'),
    (3, 'Finance',                'F', 'Oversees financial planning, accounting, and budget management.'),
    (4, 'Sales',                  'S', 'Drives revenue through client acquisition and relationship management.'),
    (5, 'Administration',         'A', 'Handles administrative operations, facilities, and compliance.');
SET IDENTITY_INSERT Departments OFF;
GO

-- ─────────────────────────────────────────────
-- Seed EmployeeCodeSequences (one row per dept)
-- ─────────────────────────────────────────────
INSERT INTO EmployeeCodeSequences (DepartmentId, LastSequence) VALUES
    (1, 0), (2, 0), (3, 0), (4, 0), (5, 0);
GO

-- ─────────────────────────────────────────────
-- Seed Roles
-- ─────────────────────────────────────────────
SET IDENTITY_INSERT Roles ON;
INSERT INTO Roles (RoleId, RoleName, DepartmentId, Description) VALUES
    (1,  'Software Engineer',        1, 'Develops and maintains software applications.'),
    (2,  'Senior Software Engineer', 1, 'Leads development tasks and mentors junior engineers.'),
    (3,  'DevOps Engineer',          1, 'Manages CI/CD pipelines and cloud infrastructure.'),
    (4,  'HR Executive',             2, 'Handles HR operations and employee engagement.'),
    (5,  'HR Manager',               2, 'Oversees the HR department and policies.'),
    (6,  'Accountant',               3, 'Maintains financial records and reports.'),
    (7,  'Finance Manager',          3, 'Leads financial strategy and planning.'),
    (8,  'Sales Executive',          4, 'Handles client outreach and deal closures.'),
    (9,  'Sales Manager',            4, 'Manages the sales team and targets.'),
    (10, 'Admin Executive',          5, 'Manages day-to-day administrative tasks.'),
    (11, 'Office Manager',           5, 'Oversees office operations and facilities.');
SET IDENTITY_INSERT Roles OFF;
GO

-- ─────────────────────────────────────────────
-- Helper: generate employee code from dept code + sequence
-- ─────────────────────────────────────────────
-- We'll insert employees manually and update sequences afterwards.

-- ─────────────────────────────────────────────
-- Seed Employees (20 records)
-- ─────────────────────────────────────────────
SET IDENTITY_INSERT Employees ON;
INSERT INTO Employees
    (EmployeeId, EmployeeCode, FullName, Email, MobileNumber, Gender, DateOfBirth, Address, DepartmentId, RoleId, JoiningDate, AnnualSalary, EmployeeStatus)
VALUES
-- IT Department (I0001 – I0006)
    (1,  'I0001', 'Rahul Sharma',     'rahul.sharma@company.com',     '9876543210', 'Male',   '1992-05-14', '12 MG Road, Bengaluru, Karnataka 560001', 1, 1,  '2021-03-01', 600000,  'Active'),
    (2,  'I0002', 'Priya Patel',      'priya.patel@company.com',      '8765432109', 'Female', '1994-08-22', '45 Linking Road, Mumbai, Maharashtra 400050', 1, 2, '2020-07-15', 950000,  'Active'),
    (3,  'I0003', 'Arjun Nair',       'arjun.nair@company.com',       '7654321098', 'Male',   '1990-11-30', '78 Anna Salai, Chennai, Tamil Nadu 600002',   1, 3,  '2019-01-10', 850000,  'Active'),
    (4,  'I0004', 'Sneha Gupta',      'sneha.gupta@company.com',      '6543210987', 'Female', '1996-03-18', '22 Park Street, Kolkata, West Bengal 700016',  1, 1,  '2022-06-20', 550000,  'Active'),
    (5,  'I0005', 'Vikram Singh',     'vikram.singh@company.com',     '9988776655', 'Male',   '1988-07-09', '9 Civil Lines, Delhi 110054',                  1, 2,  '2018-09-05', 1100000, 'Active'),
    (6,  'I0006', 'Meera Joshi',      'meera.joshi@company.com',      '9876501234', 'Female', '1998-01-25', '33 FC Road, Pune, Maharashtra 411004',         1, 1,  '2023-02-14', 480000,  'Inactive'),
-- HR Department (H0001 – H0004)
    (7,  'H0001', 'Ananya Reddy',     'ananya.reddy@company.com',     '8899001122', 'Female', '1993-04-11', '56 Jubilee Hills, Hyderabad, Telangana 500033', 2, 4, '2020-04-01', 520000,  'Active'),
    (8,  'H0002', 'Suresh Kumar',     'suresh.kumar@company.com',     '7788990011', 'Male',   '1985-12-03', '14 Residency Road, Bengaluru, Karnataka 560025',2, 5, '2017-08-20', 820000,  'Active'),
    (9,  'H0003', 'Divya Menon',      'divya.menon@company.com',      '9900112233', 'Female', '1997-06-27', '67 MG Road, Kochi, Kerala 682016',              2, 4, '2022-11-01', 490000,  'Active'),
    (10, 'H0004', 'Kiran Verma',      'kiran.verma@company.com',      '8811223344', 'Male',   '1991-09-15', '31 Gandhi Nagar, Jaipur, Rajasthan 302015',     2, 4, '2021-05-12', 510000,  'Inactive'),
-- Finance Department (F0001 – F0004)
    (11, 'F0001', 'Neha Agarwal',     'neha.agarwal@company.com',     '9933445566', 'Female', '1995-02-08', '88 Hazratganj, Lucknow, Uttar Pradesh 226001',  3, 6, '2021-01-20', 620000,  'Active'),
    (12, 'F0002', 'Rajesh Iyer',      'rajesh.iyer@company.com',      '8844556677', 'Male',   '1983-10-20', '5 Mylapore, Chennai, Tamil Nadu 600004',        3, 7, '2015-06-01', 1050000, 'Active'),
    (13, 'F0003', 'Pooja Desai',      'pooja.desai@company.com',      '7755667788', 'Female', '1999-08-14', '19 Paldi, Ahmedabad, Gujarat 380007',           3, 6, '2023-07-01', 450000,  'Active'),
    (14, 'F0004', 'Amit Chopra',      'amit.chopra@company.com',      '9944556677', 'Male',   '1987-03-30', '2 Sector 15, Chandigarh 160015',                3, 6, '2019-03-15', 700000,  'Active'),
-- Sales Department (S0001 – S0004)
    (15, 'S0001', 'Lakshmi Pillai',   'lakshmi.pillai@company.com',   '8822334455', 'Female', '1996-11-05', '44 Velachery, Chennai, Tamil Nadu 600042',      4, 8, '2022-03-10', 580000,  'Active'),
    (16, 'S0002', 'Rohit Malhotra',   'rohit.malhotra@company.com',   '9955443322', 'Male',   '1989-01-17', '7 Karol Bagh, New Delhi 110005',                4, 9, '2018-11-25', 920000,  'Active'),
    (17, 'S0003', 'Tanya Saxena',     'tanya.saxena@company.com',     '7744332211', 'Female', '2000-06-30', '23 Vaishali, Ghaziabad, Uttar Pradesh 201010',  4, 8, '2023-09-01', 420000,  'Active'),
    (18, 'S0004', 'Deepak Bhatt',     'deepak.bhatt@company.com',     '8833221100', 'Male',   '1986-04-22', '60 Satellite, Ahmedabad, Gujarat 380015',       4, 8, '2020-02-28', 610000,  'Inactive'),
-- Admin Department (A0001 – A0002)
    (19, 'A0001', 'Ritu Kapoor',      'ritu.kapoor@company.com',      '9966778899', 'Female', '1994-07-16', '11 Nehru Place, New Delhi 110019',              5, 10,'2021-08-01', 430000,  'Active'),
    (20, 'A0002', 'Manish Tiwari',    'manish.tiwari@company.com',    '8800994455', 'Male',   '1991-12-28', '38 Koramangala, Bengaluru, Karnataka 560034',   5, 11,'2019-10-14', 780000,  'Active');
SET IDENTITY_INSERT Employees OFF;
GO

-- ─────────────────────────────────────────────
-- Update EmployeeCodeSequences to match seeded data
-- ─────────────────────────────────────────────
UPDATE EmployeeCodeSequences SET LastSequence = 6 WHERE DepartmentId = 1;  -- IT
UPDATE EmployeeCodeSequences SET LastSequence = 4 WHERE DepartmentId = 2;  -- HR
UPDATE EmployeeCodeSequences SET LastSequence = 4 WHERE DepartmentId = 3;  -- Finance
UPDATE EmployeeCodeSequences SET LastSequence = 4 WHERE DepartmentId = 4;  -- Sales
UPDATE EmployeeCodeSequences SET LastSequence = 2 WHERE DepartmentId = 5;  -- Admin
GO

-- ─────────────────────────────────────────────
-- Seed EmployeePersonalDetails (sensitive PII)
-- ─────────────────────────────────────────────
INSERT INTO EmployeePersonalDetails (EmployeeId, AadhaarNumber, PANNumber) VALUES
    (1,  '1234-5678-9012', 'ABCDE1234F'),
    (2,  '2345-6789-0123', 'BCDEF2345G'),
    (3,  '3456-7890-1234', 'CDEFG3456H'),
    (4,  '4567-8901-2345', 'DEFGH4567I'),
    (5,  '5678-9012-3456', 'EFGHI5678J'),
    (6,  '6789-0123-4567', 'FGHIJ6789K'),
    (7,  '7890-1234-5678', 'GHIJK7890L'),
    (8,  '8901-2345-6789', 'HIJKL8901M'),
    (9,  '9012-3456-7890', 'IJKLM9012N'),
    (10, '0123-4567-8901', 'JKLMN0123O'),
    (11, '1234-5678-0001', 'KLMNO1234P'),
    (12, '2345-6789-0002', 'LMNOP2345Q'),
    (13, '3456-7890-0003', 'MNOPQ3456R'),
    (14, '4567-8901-0004', 'NOPQR4567S'),
    (15, '5678-9012-0005', 'OPQRS5678T'),
    (16, '6789-0123-0006', 'PQRST6789U'),
    (17, '7890-1234-0007', 'QRSTU7890V'),
    (18, '8901-2345-0008', 'RSTUV8901W'),
    (19, '9012-3456-0009', 'STUVW9012X'),
    (20, '0123-4567-0010', 'TUVWX0123Y');
GO

-- ─────────────────────────────────────────────
-- Seed EmployeeTransferHistory (sample transfers)
-- ─────────────────────────────────────────────
-- Transfer 1: Rahul Sharma (I0001) from IT to HR (becomes H0005)
-- This is historical only; his current code remains I0001 in seed
INSERT INTO EmployeeTransferHistory
    (EmployeeId, OldDepartmentId, NewDepartmentId, OldEmployeeCode, NewEmployeeCode, OldRoleId, NewRoleId, TransferDate, TransferReason)
VALUES
    (1, 1, 2, 'I0001', 'H0005', 1, 4, '2023-06-01',
     'Employee requested cross-department movement to broaden skill set and explore HR operations.'),
    (7, 2, 1, 'H0001', 'I0007', 4, 1, '2022-09-15',
     'Transferred to IT department due to technical background and organizational restructuring.'),
    (11, 3, 4, 'F0001', 'S0005', 6, 8, '2024-01-10',
     'Strategic transfer to strengthen sales team with analytical expertise from Finance.');
GO

-- ─────────────────────────────────────────────
-- Seed Users  (BCrypt hash of Admin@123 etc.)
-- NOTE: Replace hashes with actual BCrypt output from your app
-- The hashes below are placeholders; the backend will validate correctly
-- after you run the app's seed utility or use the default login.
-- ─────────────────────────────────────────────
-- BCrypt hash for 'Admin@123'    (cost 11)
-- BCrypt hash for 'Manager@123'  (cost 11)
-- BCrypt hash for 'Employee@123' (cost 11)
-- These are generated by BCrypt.Net-Next
INSERT INTO Users (Email, PasswordHash, UserRole, EmployeeId, IsActive) VALUES
    ('admin@company.com',    '$2a$11$rBLPiKHEP.Y0/X3.W1L4CuKP.R3LG4xMklN5nQvlNJpWKPHgZTIiS', 'Admin',    NULL, 1),
    ('manager@company.com',  '$2a$11$G8Bz.BRsJNqsAfwBJ2Q0o.EiMk5kXN4yPBdIlk3HFCHflKNl3Klkq', 'Manager',  2,    1),
    ('employee@company.com', '$2a$11$cQ6gRbMR8vxVx5o4Ge3M/.gPBNn2.wOH2xoKqJk0AQNDVnlQ3TdR.', 'Employee', 1,    1);
GO

PRINT 'Seed data inserted successfully.';
GO
