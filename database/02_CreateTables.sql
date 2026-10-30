-- ============================================================
-- Script 02: Create Tables
-- Employee Management System
-- ============================================================

USE EmployeeManagementDB;
GO

-- ─────────────────────────────────────────────
-- 1. Departments
-- ─────────────────────────────────────────────
CREATE TABLE Departments (
    DepartmentId    INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName  NVARCHAR(100)   NOT NULL,
    DepartmentCode  CHAR(1)         NOT NULL,   -- I, H, F, S, A, ...
    Description     NVARCHAR(500)   NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT UQ_Departments_Name  UNIQUE (DepartmentName),
    CONSTRAINT UQ_Departments_Code  UNIQUE (DepartmentCode)
);
GO

-- ─────────────────────────────────────────────
-- 2. Roles
-- ─────────────────────────────────────────────
CREATE TABLE Roles (
    RoleId          INT IDENTITY(1,1) PRIMARY KEY,
    RoleName        NVARCHAR(100)   NOT NULL,
    DepartmentId    INT             NULL,       -- NULL = role can span departments
    Description     NVARCHAR(500)   NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_Roles_Department FOREIGN KEY (DepartmentId)
        REFERENCES Departments (DepartmentId),
    CONSTRAINT UQ_Roles_Name UNIQUE (RoleName)
);
GO

-- ─────────────────────────────────────────────
-- 3. EmployeeCodeSequences  (dept-wise auto-increment)
-- ─────────────────────────────────────────────
CREATE TABLE EmployeeCodeSequences (
    SequenceId      INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentId    INT             NOT NULL,
    LastSequence    INT             NOT NULL DEFAULT 0,
    UpdatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_EmpCodeSeq_Department FOREIGN KEY (DepartmentId)
        REFERENCES Departments (DepartmentId),
    CONSTRAINT UQ_EmpCodeSeq_Dept UNIQUE (DepartmentId)
);
GO

-- ─────────────────────────────────────────────
-- 4. Employees  (main entity)
-- ─────────────────────────────────────────────
CREATE TABLE Employees (
    EmployeeId      INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeCode    NVARCHAR(10)    NOT NULL,
    FullName        NVARCHAR(150)   NOT NULL,
    Email           NVARCHAR(200)   NOT NULL,
    MobileNumber    CHAR(10)        NOT NULL,
    Gender          NVARCHAR(10)    NOT NULL,   -- Male / Female / Other
    DateOfBirth     DATE            NOT NULL,
    Address         NVARCHAR(500)   NOT NULL,
    DepartmentId    INT             NOT NULL,
    RoleId          INT             NOT NULL,
    JoiningDate     DATE            NOT NULL,
    AnnualSalary    DECIMAL(18,2)   NOT NULL,
    EmployeeStatus  NVARCHAR(20)    NOT NULL DEFAULT 'Active', -- Active / Inactive
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT UQ_Employees_Code    UNIQUE (EmployeeCode),
    CONSTRAINT UQ_Employees_Email   UNIQUE (Email),
    CONSTRAINT FK_Employees_Dept    FOREIGN KEY (DepartmentId)
        REFERENCES Departments (DepartmentId),
    CONSTRAINT FK_Employees_Role    FOREIGN KEY (RoleId)
        REFERENCES Roles (RoleId),
    CONSTRAINT CK_Employees_Gender  CHECK (Gender IN ('Male','Female','Other')),
    CONSTRAINT CK_Employees_Status  CHECK (EmployeeStatus IN ('Active','Inactive')),
    CONSTRAINT CK_Employees_Salary  CHECK (AnnualSalary > 0)
);
GO

-- ─────────────────────────────────────────────
-- 5. EmployeePersonalDetails  (sensitive PII)
-- ─────────────────────────────────────────────
CREATE TABLE EmployeePersonalDetails (
    PersonalDetailId INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeId       INT             NOT NULL,
    AadhaarEncrypted NVARCHAR(500)   NOT NULL,  -- AES-256 encrypted
    AadhaarHash      VARCHAR(64)     NOT NULL,  -- HMAC-SHA256 for unique lookup
    PANEncrypted     NVARCHAR(500)   NOT NULL,  -- AES-256 encrypted
    PANHash          VARCHAR(64)     NOT NULL,  -- HMAC-SHA256 for unique lookup
    UpdatedAt        DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_EmpPD_Employee FOREIGN KEY (EmployeeId)
        REFERENCES Employees (EmployeeId) ON DELETE CASCADE,
    CONSTRAINT UQ_EmpPD_AadhaarHash UNIQUE (AadhaarHash),
    CONSTRAINT UQ_EmpPD_PANHash     UNIQUE (PANHash)
);
GO

-- ─────────────────────────────────────────────
-- 6. EmployeeTransferHistory
-- ─────────────────────────────────────────────
CREATE TABLE EmployeeTransferHistory (
    TransferId          INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeId          INT             NOT NULL,
    OldDepartmentId     INT             NOT NULL,
    NewDepartmentId     INT             NOT NULL,
    OldEmployeeCode     NVARCHAR(10)    NOT NULL,
    NewEmployeeCode     NVARCHAR(10)    NOT NULL,
    OldRoleId           INT             NOT NULL,
    NewRoleId           INT             NOT NULL,
    TransferDate        DATE            NOT NULL,
    TransferReason      NVARCHAR(1000)  NOT NULL,
    TransferredBy       INT             NULL,       -- FK to Users (nullable)
    CreatedAt           DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT FK_ETH_Employee    FOREIGN KEY (EmployeeId)
        REFERENCES Employees (EmployeeId),
    CONSTRAINT FK_ETH_OldDept    FOREIGN KEY (OldDepartmentId)
        REFERENCES Departments (DepartmentId),
    CONSTRAINT FK_ETH_NewDept    FOREIGN KEY (NewDepartmentId)
        REFERENCES Departments (DepartmentId),
    CONSTRAINT FK_ETH_OldRole    FOREIGN KEY (OldRoleId)
        REFERENCES Roles (RoleId),
    CONSTRAINT FK_ETH_NewRole    FOREIGN KEY (NewRoleId)
        REFERENCES Roles (RoleId)
);
GO

-- ─────────────────────────────────────────────
-- 7. Users  (for auth)
-- ─────────────────────────────────────────────
CREATE TABLE Users (
    UserId          INT IDENTITY(1,1) PRIMARY KEY,
    Email           NVARCHAR(200)   NOT NULL,
    PasswordHash    NVARCHAR(300)   NOT NULL,
    UserRole        NVARCHAR(20)    NOT NULL DEFAULT 'Employee', -- Admin / Manager / Employee
    EmployeeId      INT             NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    LastLoginAt     DATETIME2       NULL,
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT UQ_Users_Email       UNIQUE (Email),
    CONSTRAINT CK_Users_Role        CHECK (UserRole IN ('Admin','Manager','Employee')),
    CONSTRAINT FK_Users_Employee    FOREIGN KEY (EmployeeId)
        REFERENCES Employees (EmployeeId)
);
GO

-- ─────────────────────────────────────────────
-- Indexes for search / filter performance
-- ─────────────────────────────────────────────
CREATE INDEX IX_Employees_DeptId      ON Employees (DepartmentId);
CREATE INDEX IX_Employees_RoleId      ON Employees (RoleId);
CREATE INDEX IX_Employees_Status      ON Employees (EmployeeStatus);
CREATE INDEX IX_Employees_Gender      ON Employees (Gender);
CREATE INDEX IX_Employees_JoiningDate ON Employees (JoiningDate);
CREATE INDEX IX_Employees_Salary      ON Employees (AnnualSalary);
CREATE INDEX IX_Employees_FullName    ON Employees (FullName);
CREATE INDEX IX_ETH_EmployeeId        ON EmployeeTransferHistory (EmployeeId);
GO

PRINT 'All tables created successfully.';
GO
