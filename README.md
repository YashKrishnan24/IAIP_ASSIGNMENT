# Employee Management System

A production-grade, full-stack Employee Management System developed with ASP.NET Core 8 Web API, Microsoft SQL Server, and a modern, responsive vanilla HTML5/CSS3/JavaScript frontend.

---

## 1. Technology Stack

| Layer | Technology | Description |
|:---|:---|:---|
| **Frontend** | HTML5, Modern CSS3, JavaScript (ES6+) | Responsive single-page architecture, modern monochrome UI, zero external frontend runtime dependencies. |
| **Backend** | ASP.NET Core 8 Web API (C#) | RESTful architecture, Entity Framework Core 8, Repository/Service pattern. |
| **Database** | Microsoft SQL Server 2022 | Relational schema, stored procedures, department sequences, and audit history. |
| **Authentication**| JWT (JSON Web Tokens) | Role-Based Access Control (Admin, Manager, Employee) with claim authorization. |
| **API Documentation** | Swagger / OpenAPI 3.0 | Interactive API testing interface (`/swagger`). |

---

## 2. Project Architecture

```
IAIP_ASSIGNMENT/
├── frontend/                               # Web client application
│   ├── index.html                          # Executive dashboard with workforce metrics
│   ├── login.html                          # Secure authentication portal
│   ├── employees.html                      # Employee directory, CRUD forms & modals
│   ├── transfers.html                      # Department transfer history & audit logs
│   ├── css/
│   │   └── style.css                       # Modern subtle monochrome design system
│   └── js/
│       ├── api.js                          # Fetch wrapper for all REST endpoints
│       ├── auth.js                         # JWT token storage and role helpers
│       ├── config.js                       # API base URL and app configuration
│       ├── employees.js                    # Directory search, filters, pagination, CRUD
│       └── utils.js                        # Form validation, formatting, toasts, modals
├── backend/
│   ├── EmployeeManagement.sln              # Solution file
│   ├── test_suite.ps1                      # Automated end-to-end test suite (34 tests)
│   └── EmployeeManagement.API/
│       ├── Controllers/                    # Auth, Employees, Lookup controllers
│       ├── Services/                       # AuthService, EmployeeService
│       ├── Models/                         # Database entities and request/response DTOs
│       ├── Data/                           # EF Core AppDbContext
│       ├── Utils/                          # BCrypt utility generator
│       ├── Properties/launchSettings.json  # Port 5000 configuration
│       ├── appsettings.json                # Connection strings and JWT configuration
│       ├── Program.cs                      # Dependency injection, middleware & security
│       └── EmployeeManagement.API.csproj   # NuGet dependency specifications
├── database/
│   ├── 01_CreateDatabase.sql               # Database initialization & collation
│   ├── 02_CreateTables.sql                 # Schema definition, keys, indexes & constraints
│   ├── 03_SeedData.sql                     # Seed data (5 depts, 11 roles, 20 employees, 3 users)
│   └── 04_StoredProcedures.sql             # Stored procedures for code generation & transfers
└── README.md                               # Project documentation & execution guide
```

---

## 3. Database Setup

### Option A: Using Docker (Recommended)
If using Docker Desktop:
```powershell
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Password@123" -p 1433:1433 --name sqlserver2022 -d mcr.microsoft.com/mssql/server:2022-latest
```

Execute the database scripts sequentially using the container's `sqlcmd`:
```powershell
docker cp database sqlserver2022:/tmp/database
docker exec sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Password@123" -C -i /tmp/database/01_CreateDatabase.sql
docker exec sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Password@123" -C -i /tmp/database/02_CreateTables.sql
docker exec sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Password@123" -C -i /tmp/database/03_SeedData.sql
docker exec sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Password@123" -C -i /tmp/database/04_StoredProcedures.sql
```

### Option B: Using SQL Server Management Studio (SSMS) / Azure Data Studio
1. Connect to your SQL Server instance (e.g. `.\SQLEXPRESS` or `localhost`).
2. Open and execute the scripts in [`database/`](database/) in order:
   - `01_CreateDatabase.sql`
   - `02_CreateTables.sql`
   - `03_SeedData.sql`
   - `04_StoredProcedures.sql`

---

## 4. Backend Setup & Execution

1. Navigate to the backend directory:
   ```powershell
   cd backend/EmployeeManagement.API
   ```

2. Confirm the connection string in `appsettings.json`:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Server=localhost,1433;Database=EmployeeManagementDB;User Id=sa;Password=Password@123;TrustServerCertificate=True;"
   }
   ```

3. Restore NuGet dependencies and start the API:
   ```powershell
   dotnet restore
   dotnet run
   ```

4. The backend service will be live at:
   - **API Base:** `http://localhost:5000`
   - **Swagger UI:** `http://localhost:5000/swagger`

---

## 5. Frontend Setup & Execution

1. Navigate to the `frontend/` directory.
2. Serve the static assets using Python or Node:
   ```powershell
   # Using Python:
   python -m http.server 3000 --directory frontend

   # OR using npx:
   npx serve frontend -p 3000
   ```
3. Open your browser at:
   **`http://localhost:3000/login.html`**

---

## 6. Default Login Credentials

| Role | Email | Password | Access Level |
|:---|:---|:---|:---|
| **Admin** | `admin@company.com` | `Admin@123` | Full Access (CRUD, Department Transfers, Soft Delete, Unmasked PII) |
| **Manager** | `manager@company.com` | `Manager@123` | Employee Management (Create, Edit, Department Transfers) |
| **Employee** | `employee@company.com` | `Employee@123` | Read-only Directory Access (Sensitive PII Masked) |

---

## 7. Features & Requirements Matrix

### Task A — Frontend Features
- **Employee Management:** Add, View, Edit, and Deactivate/Delete operations.
- **Auto Code Generation:** Displayed on creation and automatically re-assigned upon department transfer.
- **Personal Details Modal:** Comprehensive view of employment, personal, and identity details upon clicking Employee Code or View.
- **Form Validations:**
  - Full Name: Required, alphabets and spaces only (`^[A-Za-z ]+$`).
  - Email: Valid format (`^[^\s@]+@[^\s@]+\.[^\s@]+$`).
  - Mobile: Exactly 10 digits (`^\d{10}$`).
  - Aadhaar: Exactly 12 digits with real-time formatting (`XXXX-XXXX-XXXX`).
  - PAN: Exactly 10 alphanumeric characters (`^[A-Z]{5}[0-9]{4}[A-Z]$`).
  - Date of Birth: Cannot be today or a future date.
  - Annual Salary: Must be greater than 0.
- **Global Search:** Case-insensitive search across code, name, email, mobile, department, role, address, and status (excludes Aadhaar/PAN from unrestricted search).
- **Advanced Filters:** Filter simultaneously by Department, Role, Status, Gender, Joining Date Range, and Salary Bracket.
- **Salary Filter Brackets:**
  - ₹1–3 LPA (₹1,00,000 to below ₹3,00,000)
  - ₹3–5 LPA (₹3,00,000 to below ₹5,00,000)
  - ₹5–10 LPA (₹5,00,000 to below ₹10,00,000)
  - ₹10+ LPA (₹10,00,000 and above)
  - Custom Range (Min & Max inputs)
- **Sorting & Pagination:** Ascending/Descending sort on Code, Name, Department, Role, Email, Salary, Status. Supports page sizes of 5, 10, and 20 with total record counter.
- **Department Transfers:** Interactive transfer modal allowing selection of new department, designation, transfer date, and reason. Displays updated code and maintains audit history.

### Task B — Backend REST API
- `POST /api/auth/login` — Authentication & JWT issue
- `GET /api/employees` — Server-side search, multi-filter, sort, and pagination
- `GET /api/employees/{id}` — Employee detail with role-based PII protection
- `GET /api/employees/{id}/personal-details` — Explicit personal details endpoint
- `POST /api/employees` — Create employee with database-enforced code generation
- `PUT /api/employees/{id}` — Update employee details
- `DELETE /api/employees/{id}` — Soft-delete / Deactivate (Admin only)
- `POST /api/employees/transfer` — Transactional department transfer & code reassignment
- `GET /api/employees/{id}/transfer-history` — Employee transfer audit trail
- `GET /api/departments` — Department lookup
- `GET /api/roles` — Role lookup
- `GET /api/roles/department/{deptId}` — Department-specific roles

### Task C — Database Schema
- `Departments` (DepartmentId, DepartmentName, DepartmentCode, Description)
- `Roles` (RoleId, RoleName, DepartmentId, Description)
- `EmployeeCodeSequences` (SequenceId, DepartmentId, LastSequence, UpdatedAt)
- `Employees` (EmployeeId, EmployeeCode, FullName, Email, MobileNumber, Gender, DateOfBirth, Address, DepartmentId, RoleId, JoiningDate, AnnualSalary, EmployeeStatus)
- `EmployeePersonalDetails` (DetailId, EmployeeId, AadhaarNumber, PANNumber)
- `EmployeeTransferHistory` (TransferId, EmployeeId, OldDepartmentId, NewDepartmentId, OldEmployeeCode, NewEmployeeCode, OldRoleId, NewRoleId, TransferDate, TransferReason, TransferredBy)
- `Users` (UserId, Email, PasswordHash, UserRole, EmployeeId, IsActive)

---

## 8. Automated Test Suite (34 / 34 Tests Passing)

To execute the automated end-to-end verification suite:
```powershell
powershell -ExecutionPolicy Bypass -File backend\test_suite.ps1
```

**Test Coverage Summary:**
- Authentication (Admin, Manager, Employee, Bad Password, No Token)
- Role-Based Authorization & 403 Forbidden enforcement
- PII Masking verification between roles
- Exact format validations (Name, Mobile, Aadhaar, PAN, Future DOB, Zero Salary, Duplicate Email)
- Search across permitted fields
- Single and combined multi-filter queries
- Ascending and Descending sorting across columns
- Pagination constraints (5, 10, 20 records)
- Full CRUD lifecycle and code generation
- Department Transfer with atomic code reassignment and history preservation
- Soft-delete status toggling and rejection of transfer on inactive employees

---

## 9. Dependencies & Packages (.NET 8)

| Package | Version | Purpose |
|:---|:---|:---|
| `Microsoft.EntityFrameworkCore` | 8.0.0 | Object-Relational Mapping (ORM) |
| `Microsoft.EntityFrameworkCore.SqlServer` | 8.0.0 | SQL Server Database Provider |
| `Microsoft.EntityFrameworkCore.Design` | 8.0.0 | EF Core design-time & migration tools |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | 8.0.0 | JWT Authentication Middleware |
| `Swashbuckle.AspNetCore` | 6.5.0 | OpenAPI / Swagger specification and UI |
| `BCrypt.Net-Next` | 4.0.3 | Secure salt-based password hashing |
| `System.IdentityModel.Tokens.Jwt` | 7.0.3 | JSON Web Token encoding and decoding |

Restore command:
```powershell
cd backend/EmployeeManagement.API
dotnet restore
```

---

## 10. License & Submission
Developed as part of the IAIP Assignment.
All code, database migrations, tests, and documentation are included in the repository.
