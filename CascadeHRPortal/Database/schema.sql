-- Cascade HR Portal Database Schema
-- SQL Server 2019

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CascadeHR')
BEGIN
    CREATE DATABASE CascadeHR;
END
GO

USE CascadeHR;
GO

-- Employees Table
IF OBJECT_ID('dbo.Employees', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Employees (
        EmployeeId INT IDENTITY(1,1) PRIMARY KEY,
        Username NVARCHAR(100) NOT NULL UNIQUE,
        FirstName NVARCHAR(50) NOT NULL,
        LastName NVARCHAR(50) NOT NULL,
        Email NVARCHAR(100) NOT NULL,
        Department NVARCHAR(50) NOT NULL,
        JobTitle NVARCHAR(100),
        ManagerId INT NULL,
        HireDate DATE NOT NULL,
        PhoneNumber NVARCHAR(20),
        Location NVARCHAR(100),
        Status NVARCHAR(20) DEFAULT 'Active',
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_Employees_Manager FOREIGN KEY (ManagerId) REFERENCES dbo.Employees(EmployeeId)
    );
    CREATE INDEX IX_Employees_Username ON dbo.Employees(Username);
    CREATE INDEX IX_Employees_Department ON dbo.Employees(Department);
END
GO

-- Leave Requests Table
IF OBJECT_ID('dbo.LeaveRequests', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.LeaveRequests (
        RequestId INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NOT NULL,
        LeaveType NVARCHAR(50) NOT NULL,
        StartDate DATE NOT NULL,
        EndDate DATE NOT NULL,
        TotalDays INT NOT NULL,
        Status NVARCHAR(20) DEFAULT 'Pending',
        ApproverId INT NULL,
        ApprovedDate DATETIME2 NULL,
        Notes NVARCHAR(500),
        SubmittedDate DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_LeaveRequests_Employee FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT CHK_LeaveRequests_Dates CHECK (EndDate >= StartDate)
    );
    CREATE INDEX IX_LeaveRequests_Employee ON dbo.LeaveRequests(EmployeeId);
    CREATE INDEX IX_LeaveRequests_Status ON dbo.LeaveRequests(Status);
END
GO

-- Timesheets Table
IF OBJECT_ID('dbo.Timesheets', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Timesheets (
        TimesheetId INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NOT NULL,
        WeekStartDate DATE NOT NULL,
        TotalHours DECIMAL(5,2) NOT NULL DEFAULT 0,
        Status NVARCHAR(20) DEFAULT 'Draft',
        ApprovedBy INT NULL,
        SubmittedDate DATETIME2 NULL,
        CONSTRAINT FK_Timesheets_Employee FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT UQ_Timesheets_EmployeeWeek UNIQUE (EmployeeId, WeekStartDate)
    );
    CREATE INDEX IX_Timesheets_Employee ON dbo.Timesheets(EmployeeId);
END
GO

-- Benefits Table
IF OBJECT_ID('dbo.Benefits', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Benefits (
        BenefitId INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NOT NULL,
        PlanType NVARCHAR(50) NOT NULL,
        CoverageLevel NVARCHAR(50) NOT NULL,
        EffectiveDate DATE NOT NULL,
        EndDate DATE NULL,
        MonthlyPremium DECIMAL(10,2) NOT NULL,
        Status NVARCHAR(20) DEFAULT 'Active',
        CONSTRAINT FK_Benefits_Employee FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId)
    );
    CREATE INDEX IX_Benefits_Employee ON dbo.Benefits(EmployeeId);
END
GO

-- Documents Table
IF OBJECT_ID('dbo.Documents', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Documents (
        DocumentId INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NOT NULL,
        DocumentType NVARCHAR(50) NOT NULL,
        FileName NVARCHAR(255) NOT NULL,
        FilePath NVARCHAR(500) NOT NULL,
        Category NVARCHAR(50),
        UploadDate DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_Documents_Employee FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId)
    );
    CREATE INDEX IX_Documents_Employee ON dbo.Documents(EmployeeId);
END
GO

-- Payslips Table
IF OBJECT_ID('dbo.Payslips', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payslips (
        PayslipId INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NOT NULL,
        PayPeriodYear INT NOT NULL,
        PayPeriodMonth INT NOT NULL,
        PayDate DATE NOT NULL,
        GrossPay DECIMAL(10,2) NOT NULL,
        TaxDeductions DECIMAL(10,2) NOT NULL,
        BenefitDeductions DECIMAL(10,2) NOT NULL,
        NetPay AS (GrossPay - TaxDeductions - BenefitDeductions) PERSISTED,
        DocumentPath NVARCHAR(500) NOT NULL,
        CONSTRAINT FK_Payslips_Employee FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT UQ_Payslips_EmployeePeriod UNIQUE (EmployeeId, PayPeriodYear, PayPeriodMonth)
    );
    CREATE INDEX IX_Payslips_Employee ON dbo.Payslips(EmployeeId);
END
GO

-- Insert sample data
IF NOT EXISTS (SELECT 1 FROM dbo.Employees)
BEGIN
    INSERT INTO dbo.Employees (Username, FirstName, LastName, Email, Department, JobTitle, HireDate, PhoneNumber, Location)
    VALUES 
        ('CASCADE\john.doe', 'John', 'Doe', 'john.doe@cascade.com', 'Engineering', 'Software Developer', '2018-06-15', '+1-555-0100', 'Seattle'),
        ('CASCADE\jane.smith', 'Jane', 'Smith', 'jane.smith@cascade.com', 'HR', 'HR Manager', '2016-03-20', '+1-555-0101', 'Seattle'),
        ('CASCADE\bob.johnson', 'Bob', 'Johnson', 'bob.johnson@cascade.com', 'Engineering', 'Senior Developer', '2015-01-10', '+1-555-0102', 'Seattle');
    
    UPDATE dbo.Employees SET ManagerId = 3 WHERE EmployeeId = 1;
    PRINT 'Sample employees inserted';
END
GO

PRINT 'Database schema created successfully';
GO
