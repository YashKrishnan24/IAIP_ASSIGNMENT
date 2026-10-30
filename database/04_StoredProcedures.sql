-- ============================================================
-- Script 04: Stored Procedures
-- Employee Management System
-- ============================================================

USE EmployeeManagementDB;
GO

-- ─────────────────────────────────────────────
-- SP: Generate next Employee Code for a department
-- Concurrency safe with UPDLOCK, ROWLOCK
-- ─────────────────────────────────────────────
CREATE OR ALTER PROCEDURE sp_GenerateEmployeeCode
    @DepartmentId   INT,
    @NewCode        NVARCHAR(10) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @DeptCode   CHAR(1);
            DECLARE @NextSeq    INT;

            SELECT @DeptCode = DepartmentCode
            FROM   Departments
            WHERE  DepartmentId = @DepartmentId;

            IF @DeptCode IS NULL
                THROW 50001, 'Department not found.', 1;

            -- Atomic increment with UPDLOCK, ROWLOCK prevents race conditions
            UPDATE EmployeeCodeSequences WITH (UPDLOCK, ROWLOCK)
            SET    LastSequence = LastSequence + 1,
                   UpdatedAt   = GETUTCDATE()
            WHERE  DepartmentId = @DepartmentId;

            SELECT @NextSeq = LastSequence
            FROM   EmployeeCodeSequences
            WHERE  DepartmentId = @DepartmentId;

            SET @NewCode = @DeptCode + RIGHT('0000' + CAST(@NextSeq AS NVARCHAR(4)), 4);
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

-- ─────────────────────────────────────────────
-- SP: Transfer Employee between departments
-- ─────────────────────────────────────────────
CREATE OR ALTER PROCEDURE sp_TransferEmployee
    @EmployeeId      INT,
    @NewDepartmentId INT,
    @NewRoleId       INT,
    @TransferDate    DATE,
    @TransferReason  NVARCHAR(1000),
    @TransferredBy   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            -- Validate employee exists and is active
            DECLARE @CurrentDeptId   INT;
            DECLARE @CurrentRoleId   INT;
            DECLARE @CurrentCode     NVARCHAR(10);

            SELECT @CurrentDeptId = DepartmentId,
                   @CurrentRoleId = RoleId,
                   @CurrentCode   = EmployeeCode
            FROM   Employees
            WHERE  EmployeeId     = @EmployeeId
              AND  EmployeeStatus = 'Active';

            IF @CurrentDeptId IS NULL
                THROW 50002, 'Employee not found or is inactive.', 1;

            -- Prevent transfer to same department
            IF @CurrentDeptId = @NewDepartmentId
                THROW 50003, 'Employee is already in the target department.', 1;

            -- Generate new employee code atomically
            DECLARE @NewCode NVARCHAR(10);
            EXEC sp_GenerateEmployeeCode @NewDepartmentId, @NewCode OUTPUT;

            -- Update employee
            UPDATE Employees
            SET    DepartmentId  = @NewDepartmentId,
                   RoleId        = @NewRoleId,
                   EmployeeCode  = @NewCode,
                   UpdatedAt     = GETUTCDATE()
            WHERE  EmployeeId    = @EmployeeId;

            -- Record transfer history
            INSERT INTO EmployeeTransferHistory
                (EmployeeId, OldDepartmentId, NewDepartmentId, OldEmployeeCode, NewEmployeeCode,
                 OldRoleId, NewRoleId, TransferDate, TransferReason, TransferredBy)
            VALUES
                (@EmployeeId, @CurrentDeptId, @NewDepartmentId, @CurrentCode, @NewCode,
                 @CurrentRoleId, @NewRoleId, @TransferDate, @TransferReason, @TransferredBy);

            -- Return updated employee code
            SELECT @NewCode AS NewEmployeeCode;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

-- ─────────────────────────────────────────────
-- SP: Search / Filter / Sort / Paginate Employees
-- ─────────────────────────────────────────────
CREATE OR ALTER PROCEDURE sp_GetEmployees
    @Search              NVARCHAR(200)   = NULL,
    @DepartmentId        INT             = NULL,
    @RoleId              INT             = NULL,
    @Status              NVARCHAR(20)    = NULL,
    @Gender              NVARCHAR(10)    = NULL,
    @JoiningDateFrom     DATE            = NULL,
    @JoiningDateTo       DATE            = NULL,
    @MinSalary           DECIMAL(18,2)   = NULL,
    @MaxSalary           DECIMAL(18,2)   = NULL,
    @IsCustomSalaryRange BIT             = 0,
    @SortBy              NVARCHAR(50)    = 'EmployeeCode',
    @SortDirection       NVARCHAR(4)     = 'ASC',
    @PageNumber          INT             = 1,
    @PageSize            INT             = 10,
    @TotalCount          INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Sanitise sort column (whitelist)
    IF @SortBy NOT IN ('EmployeeCode','FullName','Email','MobileNumber','Gender',
                       'DepartmentName','RoleName','JoiningDate','AnnualSalary','EmployeeStatus')
        SET @SortBy = 'EmployeeCode';

    IF @SortDirection NOT IN ('ASC','DESC')
        SET @SortDirection = 'ASC';

    -- Build dynamic query
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @params NVARCHAR(MAX);

    SET @sql = N'
    WITH FilteredEmployees AS (
        SELECT
            e.EmployeeId,
            e.EmployeeCode,
            e.FullName,
            e.Email,
            e.MobileNumber,
            e.Gender,
            e.DateOfBirth,
            e.Address,
            e.DepartmentId,
            d.DepartmentName,
            e.RoleId,
            r.RoleName,
            e.JoiningDate,
            e.AnnualSalary,
            e.EmployeeStatus,
            e.CreatedAt
        FROM   Employees e
        INNER JOIN Departments d ON e.DepartmentId = d.DepartmentId
        INNER JOIN Roles       r ON e.RoleId       = r.RoleId
        WHERE 1 = 1
    ';

    -- Global search (exclude sensitive Aadhaar/PAN for security)
    IF @Search IS NOT NULL AND @Search <> ''
        SET @sql = @sql + N'
        AND (
            e.EmployeeCode    LIKE ''%'' + @Search + ''%''
         OR e.FullName        LIKE ''%'' + @Search + ''%''
         OR e.Email           LIKE ''%'' + @Search + ''%''
         OR e.MobileNumber    LIKE ''%'' + @Search + ''%''
         OR d.DepartmentName  LIKE ''%'' + @Search + ''%''
         OR r.RoleName        LIKE ''%'' + @Search + ''%''
         OR e.Address         LIKE ''%'' + @Search + ''%''
         OR e.EmployeeStatus  LIKE ''%'' + @Search + ''%''
         OR e.Gender          LIKE ''%'' + @Search + ''%''
        )';

    IF @DepartmentId IS NOT NULL
        SET @sql = @sql + N' AND e.DepartmentId = @DepartmentId';

    IF @RoleId IS NOT NULL
        SET @sql = @sql + N' AND e.RoleId = @RoleId';

    IF @Status IS NOT NULL AND @Status <> ''
        SET @sql = @sql + N' AND e.EmployeeStatus = @Status';

    IF @Gender IS NOT NULL AND @Gender <> ''
        SET @sql = @sql + N' AND e.Gender = @Gender';

    IF @JoiningDateFrom IS NOT NULL
        SET @sql = @sql + N' AND e.JoiningDate >= @JoiningDateFrom';

    IF @JoiningDateTo IS NOT NULL
        SET @sql = @sql + N' AND e.JoiningDate <= @JoiningDateTo';

    IF @MinSalary IS NOT NULL
        SET @sql = @sql + N' AND e.AnnualSalary >= @MinSalary';

    IF @MaxSalary IS NOT NULL
    BEGIN
        IF @IsCustomSalaryRange = 1
            SET @sql = @sql + N' AND e.AnnualSalary <= @MaxSalary';
        ELSE
            SET @sql = @sql + N' AND e.AnnualSalary < @MaxSalary';
    END

    SET @sql = @sql + N'
    )
    SELECT @TotalCount = COUNT(*) FROM FilteredEmployees;

    SELECT * FROM FilteredEmployees
    ORDER BY ' + QUOTENAME(@SortBy) + N' ' + @SortDirection + N'
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;';

    SET @params = N'
        @Search NVARCHAR(200),
        @DepartmentId INT,
        @RoleId INT,
        @Status NVARCHAR(20),
        @Gender NVARCHAR(10),
        @JoiningDateFrom DATE,
        @JoiningDateTo DATE,
        @MinSalary DECIMAL(18,2),
        @MaxSalary DECIMAL(18,2),
        @IsCustomSalaryRange BIT,
        @PageNumber INT,
        @PageSize INT,
        @TotalCount INT OUTPUT';

    EXEC sp_executesql @sql, @params,
        @Search, @DepartmentId, @RoleId, @Status, @Gender,
        @JoiningDateFrom, @JoiningDateTo,
        @MinSalary, @MaxSalary, @IsCustomSalaryRange,
        @PageNumber, @PageSize,
        @TotalCount OUTPUT;
END;
GO

PRINT 'Stored procedures created successfully.';
GO
