IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'HNIM')
BEGIN
    CREATE DATABASE HNIM;
END
GO

USE HNIM;
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Devices' AND xtype='U')
BEGIN
    CREATE TABLE Devices (
        ID INT PRIMARY KEY IDENTITY(1,1),
        Name VARCHAR(255) NOT NULL,
        IP VARCHAR(50),
        Category VARCHAR(100),
        SerialNumber VARCHAR(100),
        Details TEXT,
        Status VARCHAR(20) DEFAULT 'unknown',
        LastSeen DATETIME,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Maintenance' AND xtype='U')
BEGIN
    CREATE TABLE Maintenance (
        ID INT PRIMARY KEY IDENTITY(1,1),
        DeviceID INT FOREIGN KEY REFERENCES Devices(ID),
        Action VARCHAR(255),
        PerformedAt DATETIME DEFAULT GETDATE(),
        NextMaintenanceAt DATETIME,
        Notes TEXT
    );
END
