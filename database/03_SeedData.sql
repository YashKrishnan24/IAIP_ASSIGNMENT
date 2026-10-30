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
-- Seed EmployeePersonalDetails (AES-256 Encrypted with HMAC-SHA256 Hashes)
-- ─────────────────────────────────────────────
INSERT INTO EmployeePersonalDetails (EmployeeId, AadhaarEncrypted, AadhaarHash, PANEncrypted, PANHash) VALUES
    (1, '6r/YoJMbI9hPUTrTlwBm7DR0OIGZcTkekHasK3vXM90=', 'D0BD404790FB83CA87275887571A631416F4E986B5525E64300AD270740D0CC0', 'GoPdrCdJG5G7CrIp+cBEc4foOlpqa4VaY37MBhJ9atc=', '0191C95841153AA3DE253E57E3E35A3ACACA1CC90D4EE43D2793AAD050278D2B'),
    (2, 'Om+x0JyOXJAvv5mIJawmSVZXgZDmkRJrPpALl8YxdKc=', 'FC7F8E5AEF219BFEB5C9F37E340CA961C1915CB4C2EBAFE992F440B8D2B11419', 'hG3j3DM4kX/iDHZv1IE+RlyoQ/CbXKuZLHkt9GZXEc0=', '9E774CEF8773BA31C201AA102D196EDC193285CBE514604BA4C36A99340029F9'),
    (3, 'Cq+MDVkIehXdBNEjCl8tCm+8ayfWEDMNTWJ7XmlCyu4=', 'FFCFD8E1C60552B5936B4936E44362FF9B62CFF00F48185F05A464D4EAE631B2', 'RymrfrjllFo6PMPOliiOdoLRueU+7sSyK3gcfhF38fk=', '1B5DED25065F7393F4627EB630A00C3393A9C46ADF572A635D55C9A65C7CFC6A'),
    (4, 'Iww/N1OQiHvUmniosAMmrD5hrzGp/1xckJ/+N+Y/EDQ=', '338EB9974B38BBA4458D3C998C9F668C57A7EE3B66549D366C675DB3B6377C41', 'Cdsv+nv7oOuR6OyoH13iXd1AXkBeKvfcFUPS550OJWY=', 'EE7632FAFA8ACCB0C35BDB75AB1808F7417F43A0FE6862C4DD58637C15B2D027'),
    (5, '2QFb+2pljVgtHZq2iHVkYSEryRom8yYBs1d6oKa/nKk=', '99C673313BC2010D6BE3C39225853259F1C9873A2D0F1AB67029007E0A3B9C68', 'ij2/XB8qfhfX2j+QRc8KWve3KB63CB6XiMUjrvBd6i0=', '6747ECAEF2125994ADAFCB022B99684504F6F82FD40F431583BF4A6E62CFD1D4'),
    (6, 'ewDbHX/4Bx7xtR3tbXiHrvSt7Qq8wg0iuWDtNw79uY4=', 'AA455E27431676FCB254C102A09B3C32A1E83579FED5FDBC25A70851FA43FB07', 'GE00MZ+AsqoMSuFTnthGiLcIcuqSQWFlGRIINa0EoCU=', '06D81005FC1D427CED748E37555821D781F8C0F5DF27E34BF0BDCD9EC08E6C56'),
    (7, 'zDKE8Ewx69O2zxCwbUK7V1ug0+BlxQobCftfqImGsSo=', 'BD317C9D3CBBBF520D759659F48C9D36A7BFFD7BABE67135018BBDC857E95920', 'DznMj4uXrGvz05Qn2pG9JK0U6YZqHj17wdSoIUiJ6DQ=', '2C8C93D26E0931722F90B5676D7F2F656E69F904B325A0B5D10C6FF16C20B2AF'),
    (8, 'hMRIS8QGy1UKpXyEng3OZut+BmMP46Mv7u6fnr+4Rjw=', '5F58D1357742D370ADF07AF998B38D93ABB182B2878CDB5A75B0F26513AB578F', 'unVtPwVeQ9Tv9/oJEok4AQzD7P6lsRIiN3RhEXiV0js=', '6902C4301B529FE7A521C447785A92C1113A1E3427575B2E9C86601FBDE47E76'),
    (9, 'q8khGBxU1eBG33TAAqtIw21ztMx2vqCqZJyDUQwORAU=', '00A2B11CDDB1693FDE40E467F61DF603401E55A6550404D13979E8E8546004D5', 'SOBzTG3xofkPOASvF3CPgjkqHr8SZXT5evELL8nnzIU=', '4262DD6FE96D128893AA449D07F47C1511AD75E728CA9B714FCACBCD270ACDA5'),
    (10, 'MNmV9BMMksAoX7+HkopV1ImKnZWPa4OGyaYV2S/FIeU=', 'AEF5A76B18FDE51C9DFE450626F15E8C2EF79EEAB2E2A8A16DE094CBB4139391', 'g7D6WlsTMkD9rr6X3lckEldIa9C/0HpCtfLKzcT8u+s=', '2D5BC5BC087B76D2D7E4CE800F716F0787CF076FF94E5D640AACA65A61D1D56E'),
    (11, '6krRs+UYLTC1CNtH9pX6YTh2fH2Bi4Ktz/qqpX1La6s=', '3F8F3AB7BF888BB1C096D33DCFB65A686212A2EC67D28B1E74F33ABF52A1B4CD', 'x7YQVgfgrftlHwo3AABExtr8MuNV6/2wEmSI1PFfMiY=', '69A893D5426ED42F94FA6D540A85CF881C857747F9D314C15A9DFA51EA798C32'),
    (12, '2F5VXUnvh1iZe2QH/Ecrl/C5R8I/YckP4K2fIsMSBlU=', '43694038F83EF662A24508B33A1831937AD329BFC240F077A36792C924818A71', '3ib3THlNVUYBMbbbjZpqaU4F/mrEZLfrxm2FHra+/54=', '85D63C700F05E840224CFB20E05ECD7CE48CFB30124B25D582AABC8A5DBCFA31'),
    (13, 'uuhdoRPTpQn5vBR6bvOsEtw4XrlLqhbCCi+U38rox4w=', 'D16EE834C32867CEC084E3B5580DEA07A4261B762BEA6ACB9C1F6AB89DEA310A', '6/AFR3bV5s/v70gmhQGtv2RFlWbZzW8MGgYJHWSGOfo=', 'D10D235CA3D2EAA7511DA1501406E243842CC5836F6693D9CECAF8F0D4B18AE2'),
    (14, 'EJXGXpBGha0x4KzX36YJW4u2S6VShp62D8cMjh0ly/0=', '1FD9F636FA0A49F2D7AFE863277FBE333B04A9EDDC2F89ABA50C2543EAB7F535', 'JRhEcSIvX24uyslH8OnZxL9fTNJF1y4bWzFb0kSZeKk=', '0EE07C6C245E4DF61FB6817B6B29C0F7B85DAB19289BECF479D8CC2FA5E37444'),
    (15, 'tiCjAXQ51PpKh5p9T41B6NMJnAxkmFlnNBzoDgrCGDY=', 'F0CB056BBB0489FBAF68E0B6F3E7C7E5C8A1118EFB6F4176343CA6B340B60455', 'asO4Qwhk4H5XDJvPH/tBqP1PujdgWuTmoxdRYuMVTjw=', '285D908016D90850717D892F974AD4B7AEA61DB1B3EC4EDF2EAAF974856B5C09'),
    (16, 'v5IgsUGW8gs+Br1Z3Li/yhxClS0r9pnCFyu5fBgjqFw=', '1FFC1D2E610F4F3837D69E3A5FC5A1CF16500DA052637F4703ACCDF7DD5C08AE', 'cGzR5cjEIST0YPcJ98+xYMsvIouB4NSsy5RAn5I5DgU=', '6AF48B608ADEFC355ACB17A435BA9B7F84FC1DDC1C301A21FB988818525F68BA'),
    (17, 'QJJY4uUx4CVCot5HY/aVg4+NulnyPdxZ4GJHPIUgg6s=', '5F07F838A9822B2CEFB4E24FD7FB3BA66B0285CCEA4EAEBC97C8772BCE541730', 'TY6BMPuMWsmFJbmI5loo+d5UauTC3PbUeV2C60eFUdE=', 'E9F753EDE033E1AEE6723005F927D405C6BA299CE205C3BB910D13E3EA19A839'),
    (18, '9e93dJFK66vXEUg1dudkY9R2VWYClBXzFGXscC2b9iM=', 'DD18D5A8AD08CBB49D745732366A699E346320C8E9B21E900B1DC45ADBBE3195', 'Q+Vqzp0McEZgACJbT9I337RZ4E+s8XuxhWCjPUXAa/g=', '6E505B2B20A37709F0C42B636468C03AB7E58BB01B2EDA3783634785635880FA'),
    (19, 'Ywf+JsTbXiBD/G+uDrgutOuapEe0obEK5B5FlD83y2w=', 'E6C89CB8FB58504AAF22165C7B819141EBE8014FE42E5C038B81B7327513EE3E', 'G5OhFmbuw77yjbY8ox6Fjn+XDFwG6UV3KIugJhyQq58=', '3FCD04DA9E79F90F7EE29579207F78A4B027EBB09415CEC98745A21E5A0286FB'),
    (20, 'q5tZII/Zz98Fb7uY31DuQ3aHrGc26u4Wz8jz8oBDB4o=', '8E414D658F0394D8C900488BD56E278B0B426A95C9D52033AB1972343FEA6CA8', 'fX7I0gQVglOSl3J/1BYXjU90ZBsCkBi78jnJK/0Wdx8=', '174E4AF917E83156B11F6E0A8580028F2446201EA9E81C51B84486297B6A1741');
GO

-- ─────────────────────────────────────────────
-- Seed EmployeeTransferHistory (Consistent with current employees)
-- ─────────────────────────────────────────────
-- Employee 6 (Meera Joshi) transferred from Admin to IT (became I0006)
-- Employee 14 (Amit Chopra) transferred from Sales to Finance (became F0004)
-- Employee 20 (Manish Tiwari) transferred from HR to Admin (became A0002)
INSERT INTO EmployeeTransferHistory
    (EmployeeId, OldDepartmentId, NewDepartmentId, OldEmployeeCode, NewEmployeeCode, OldRoleId, NewRoleId, TransferDate, TransferReason)
VALUES
    (6, 5, 1, 'A0001', 'I0006', 10, 1, '2023-02-10',
     'Internal career progression transfer from Administration to Information Technology software engineering.'),
    (14, 4, 3, 'S0001', 'F0004', 8, 6, '2022-11-15',
     'Lateral department transfer to utilize financial acumen and risk modeling capabilities in Finance.'),
    (20, 2, 5, 'H0002', 'A0002', 4, 11, '2021-05-20',
     'Promoted and transferred to Administration to lead office operations and infrastructure facilities.');
GO

-- ─────────────────────────────────────────────
-- Seed Users (BCrypt hashes for Admin@123, Manager@123, Employee@123)
-- ─────────────────────────────────────────────
INSERT INTO Users (Email, PasswordHash, UserRole, EmployeeId, IsActive) VALUES
    ('admin@company.com',    '$2a$11$Fr5lOoQwXBJNlg5g9w7xwucrVAbyd1Nkzub3pROVt7u35TkrSH9CS', 'Admin',    NULL, 1),
    ('manager@company.com',  '$2a$11$S4/NSTXRJe8vNy2YHivSUuFQnsDDj1WKTvhQ.v2K0ktMEqsAjaAKi', 'Manager',  2,    1),
    ('employee@company.com', '$2a$11$IAzt7FwzC6d.PUHGlYxGjORH6gAdCPn3RxS/bq4Uwe5VwtrFSCiWm', 'Employee', 1,    1);
GO

PRINT 'Seed data inserted successfully.';
GO
