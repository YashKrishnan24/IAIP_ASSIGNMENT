-- ============================================================
-- Script 01: Create Database
-- Employee Management System
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'EmployeeManagementDB')
BEGIN
    ALTER DATABASE EmployeeManagementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EmployeeManagementDB;
END
GO

CREATE DATABASE EmployeeManagementDB
    COLLATE SQL_Latin1_General_CP1_CI_AS;
GO

USE EmployeeManagementDB;
GO

PRINT 'Database EmployeeManagementDB created successfully.';
GO
