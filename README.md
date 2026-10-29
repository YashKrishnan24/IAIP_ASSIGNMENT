 # 🏢 Employee Management System

A fully integrated Employee Management System with CRUD operations, department transfers, auto employee code generation, global search, advanced filtering, sorting, and pagination.

## 📁 Project Structure

```
IAIP_ASSIGNMENT/
├── frontend/               # HTML/CSS/JavaScript frontend
│   ├── index.html
│   ├── css/
│   ├── js/
│   └── pages/
├── backend/                # ASP.NET Core Web API
│   ├── EmployeeManagement.API/
│   └── EmployeeManagement.sln
├── database/               # SQL Server scripts
│   ├── 01_CreateDatabase.sql
│   ├── 02_CreateTables.sql
│   ├── 03_SeedData.sql
│   └── 04_StoredProcedures.sql
└── README.md
```

## 🛠️ Technology Stack

| Layer    | Technology                        |
|----------|-----------------------------------|
| Frontend | HTML5, CSS3, Vanilla JavaScript   |
| Backend  | ASP.NET Core 8 Web API (C#)       |
| Database | SQL Server 2019+                  |
| Auth     | JWT Bearer Tokens                 |
| Docs     | Swagger / OpenAPI                 |

## ⚙️ Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [SQL Server 2019+](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) or SQL Server Express
- [SQL Server Management Studio (SSMS)](https://aka.ms/ssmsfullsetup) (optional, for DB management)
- A modern browser (Chrome, Firefox, Edge)

## 🗄️ Database Setup

1. Open **SSMS** or **Azure Data Studio**.
2. Connect to your SQL Server instance.
3. Run the scripts in order:
   ```
   database/01_CreateDatabase.sql
   database/02_CreateTables.sql
   database/03_SeedData.sql
   database/04_StoredProcedures.sql
   ```

## 🔧 Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend/EmployeeManagement.API
   ```

2. Update the connection string in `appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=YOUR_SERVER;Database=EmployeeManagementDB;Trusted_Connection=True;TrustServerCertificate=True;"
     }
   }
   ```
   > Replace `YOUR_SERVER` with your SQL Server instance name (e.g., `.\SQLEXPRESS` or `localhost`).

3. Restore NuGet packages and run:
   ```bash
   dotnet restore
   dotnet run
   ```

4. The API will be available at:
   - **API Base URL:** `https://localhost:7001` (or `http://localhost:5001`)
   - **Swagger UI:** `https://localhost:7001/swagger`

## 🌐 Frontend Setup

1. Navigate to the `frontend/` directory.
2. Open `index.html` in your browser directly, **OR**
3. Use a simple HTTP server for best experience:
   ```bash
   # Using Python
   cd frontend
   python -m http.server 3000
   # Then open http://localhost:3000
   ```
4. Update the API base URL in `frontend/js/config.js`:
   ```javascript
   const API_BASE_URL = 'https://localhost:7001/api';
   ```

## 🔐 Default Login Credentials

| Role     | Email                  | Password    |
|----------|------------------------|-------------|
| Admin    | admin@company.com      | Admin@123   |
| Manager  | manager@company.com    | Manager@123 |
| Employee | employee@company.com   | Employee@123|

## 📦 NuGet Packages Used

| Package | Version | Purpose |
|---------|---------|---------|
| Microsoft.EntityFrameworkCore | 8.0.0 | ORM |
| Microsoft.EntityFrameworkCore.SqlServer | 8.0.0 | SQL Server provider |
| Microsoft.EntityFrameworkCore.Design | 8.0.0 | Migrations |
| Microsoft.AspNetCore.Authentication.JwtBearer | 8.0.0 | JWT Auth |
| Swashbuckle.AspNetCore | 6.5.0 | Swagger UI |
| BCrypt.Net-Next | 4.0.3 | Password hashing |

### Restore Packages
```bash
cd backend/EmployeeManagement.API
dotnet restore
```

## 🚀 Running the Full Application

1. Ensure SQL Server is running and database scripts have been executed.
2. Start the backend API (`dotnet run` from backend directory).
3. Open `frontend/index.html` in browser.
4. Login with the default Admin credentials.

## 🔗 API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST   | /api/auth/login | Login |
| GET    | /api/employees | Get all employees (with filters) |
| GET    | /api/employees/{id} | Get employee by ID |
| POST   | /api/employees | Create employee |
| PUT    | /api/employees/{id} | Update employee |
| DELETE | /api/employees/{id} | Deactivate employee |
| POST   | /api/employees/transfer | Transfer department |
| GET    | /api/employees/{id}/transfer-history | Transfer history |
| GET    | /api/departments | Get departments |
| GET    | /api/roles | Get roles |

## 📋 Features

- ✅ Employee CRUD operations
- ✅ Auto-generated department-based Employee Codes
- ✅ Department Transfer with code re-assignment
- ✅ Global search across all employee fields
- ✅ Advanced filters (Department, Role, Status, Gender, Salary Range)
- ✅ Ascending/Descending sorting
- ✅ Pagination (5, 10, 20 records per page)
- ✅ Field validations (Aadhaar, PAN, Mobile, Email)
- ✅ JWT Authentication with Role-Based Authorization
- ✅ Transfer history tracking
- ✅ Responsive UI design

## 📄 License

This project is developed as part of the IAIP Assignment.
