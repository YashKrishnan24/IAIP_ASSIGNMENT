# Employee Management System

A full-stack Employee Management System developed with ASP.NET Core 8 Web API, Microsoft SQL Server, and a responsive vanilla HTML5 / CSS3 / JavaScript frontend.

---

## 1. Technology Stack

| Layer | Technology | Description |
|:---|:---|:---|
| **Frontend** | HTML5, Modern CSS3, JavaScript (ES6+) | Single-page architecture, modern monochrome UI, zero external runtime dependencies. Plain HTML/CSS/JS with no build steps or `package.json` required. |
| **Backend** | ASP.NET Core 8 Web API (C#) | RESTful architecture, Entity Framework Core 8, Service layer pattern, AES-256 encryption & HMAC-SHA256 duplicate detection. |
| **Database** | Microsoft SQL Server 2022 | Relational schema, department-based code sequences, atomic concurrency locking (`UPDLOCK, ROWLOCK`), and audit history. |
| **Authentication**| JWT (JSON Web Tokens) | Role-Based Access Control (Admin, Manager, Employee) with claim authorization. |
| **API Documentation** | Swagger / OpenAPI 3.0 & Postman | Exported in `docs/swagger.json` and `docs/EmployeeManagement.postman_collection.json`, plus interactive Swagger UI at `/swagger`. |

---

## 2. Project Architecture

```
IAIP_ASSIGNMENT/
├── frontend/                               # Web client application (Vanilla HTML/CSS/JS - no package.json needed)
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
│       ├── employees.js                    # Directory search, filters, pagination, CRUD, XSS-safe escaping
│       └── utils.js                        # Form validation, formatting, toasts, escapeHtml helper
├── backend/
│   ├── EmployeeManagement.sln              # Solution file
│   ├── nuget.config                        # NuGet package source configuration
│   ├── test_suite.ps1                      # Automated end-to-end test suite (34 tests)
│   └── EmployeeManagement.API/
│       ├── Controllers/                    # Auth, Employees, Lookup controllers
│       ├── Services/                       # AuthService, EmployeeService, EncryptionService
│       ├── Models/                         # Database entities and request/response DTOs
│       ├── Data/                           # EF Core AppDbContext with unique indexes on PII hashes
│       ├── Utils/                          # BCrypt utility generator
│       ├── Properties/launchSettings.json  # Port 5000 configuration
│       ├── appsettings.json                # Configuration with placeholders (no credentials committed)
│       ├── appsettings.example.json        # Example configuration template for developers
│       ├── appsettings.Development.json    # Local development settings (git-ignored, local secrets only)
│       ├── Program.cs                      # Global exception handler, DI, middleware & security
│       └── EmployeeManagement.API.csproj   # NuGet dependency specifications
├── database/
│   ├── 01_CreateDatabase.sql               # Database initialization & collation
│   ├── 02_CreateTables.sql                 # Schema definition, keys, indexes & constraints
│   ├── 03_SeedData.sql                     # Seed data (5 depts, 11 roles, 20 employees, 3 users, AES encrypted PII)
│   └── 04_StoredProcedures.sql             # Reference T-SQL stored procedures with UPDLOCK/ROWLOCK
├── docs/
│   ├── swagger.json                        # Exported OpenAPI 3.0 specification
│   └── EmployeeManagement.postman_collection.json # Exported Postman collection v2.1
├── nuget.config                            # Root NuGet package source configuration
└── README.md                               # Project documentation & execution guide
```

---

## 3. Database Setup

### Option A: Using Docker (Recommended)
Start a local SQL Server 2022 container:
```powershell
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Password123" -p 1433:1433 --name sqlserver2022 -d mcr.microsoft.com/mssql/server:2022-latest
```

Copy and execute the database scripts sequentially using `sqlcmd`:
```powershell
docker cp database sqlserver2022:/tmp/database
docker exec sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -i /tmp/database/01_CreateDatabase.sql
docker exec sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -i /tmp/database/02_CreateTables.sql
docker exec sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -i /tmp/database/03_SeedData.sql
docker exec sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Password123" -C -i /tmp/database/04_StoredProcedures.sql
```

### Option B: Using SQL Server Management Studio (SSMS) / Azure Data Studio
1. Connect to your SQL Server instance (e.g. `localhost,1433` or `.\SQLEXPRESS`).
2. Open and execute the scripts in [`database/`](database/) in order:
   - `01_CreateDatabase.sql`
   - `02_CreateTables.sql`
   - `03_SeedData.sql`
   - `04_StoredProcedures.sql`

---

## 4. Backend Setup & Execution

### Configuration & Credentials Isolation
To adhere to strict security best practices, `appsettings.json` contains only placeholder credentials and is safe for version control.

1. Navigate to the API directory:
   ```powershell
   cd backend/EmployeeManagement.API
   ```

2. Copy `appsettings.example.json` to `appsettings.Development.json` (which is git-ignored):
   ```powershell
   cp appsettings.example.json appsettings.Development.json
   ```

3. Update `appsettings.Development.json` with your local database password and secrets:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=localhost,1433;Database=EmployeeManagementDB;User Id=sa;Password=YourStrong@Password123;TrustServerCertificate=True;"
     },
     "JwtSettings": {
       "SecretKey": "YourCustomSecretKeyAtLeast32CharactersLong!",
       "Issuer": "EmployeeManagementAPI",
       "Audience": "EmployeeManagementClient",
       "ExpiryInMinutes": 60
     },
     "Encryption": {
       "Key": "YourCustomAES256Key32CharactersLong!"
     }
   }
   ```

4. Restore NuGet packages and start the API:
   ```powershell
   dotnet restore
   dotnet run
   ```

5. The backend service will be live at:
   - **API Base:** `http://localhost:5000`
   - **Swagger UI:** `http://localhost:5000/swagger`

---

## 5. Frontend Setup & Execution

The frontend is built using standard HTML5, CSS3, and ES6 JavaScript. It has **no external runtime package dependencies** and **does not require `package.json` or `npm install`**.

1. Navigate to the `frontend/` directory or project root.
2. Serve static files with any HTTP server (e.g., Python built-in server):
   ```powershell
   # Using Python 3:
   python -m http.server 3000 --directory frontend

   # OR using npx serve:
   npx serve frontend -p 3000
   ```
3. Open your browser and navigate to:
   **`http://localhost:3000/login.html`**

---

## 6. Default Login Credentials

| Role | Email | Password | Access Level |
|:---|:---|:---|:---|
| **Admin** | `admin@company.com` | `Admin@123` | Full Access (CRUD, Department Transfers, Soft Delete, Full Unmasked PII) |
| **Manager** | `manager@company.com` | `Manager@123` | Employee Management (Create, Edit, Department Transfers) |
| **Employee** | `employee@company.com` | `Employee@123` | Read-only Directory Access (Sensitive Aadhaar/PAN PII Masked) |

---

## 7. Security & Architecture Details

### PII Protection & Dual AES-256 / HMAC Hashing
- Sensitive government identifiers (Aadhaar Number and PAN Number) are encrypted at rest using AES-256 (CBC with random IV prepended).
- To allow fast uniqueness enforcement and duplicate rejection without decrypting the entire database, a deterministic HMAC-SHA256 hash is computed and stored in indexed unique columns (`AadhaarHash`, `PANHash`).
- Unprivileged users (`Employee` role) receive masked identifiers (`****-****-1234` and `******1234F`).
- Global search explicitly excludes Aadhaar and PAN numbers to prevent unauthorized enumeration.

### Atomic Sequence Generation & Race Prevention
- Employee codes (`I0001`, `H0001`, `F0001`, `S0001`, `A0001`) are generated atomically inside database transactions.
- The sequence table uses `WITH (UPDLOCK, ROWLOCK)` and `OUTPUT inserted.LastSequence`, guaranteeing that concurrent creates or transfers never race or produce duplicate codes.

### Stored Procedures Reference
- `database/04_StoredProcedures.sql` provides T-SQL reference implementations (`sp_GenerateEmployeeCode`, `sp_TransferEmployee`, `sp_GetEmployees`) for DBA inspection or pure-SQL deployment.
- The ASP.NET Core API implements the business domain logic via Entity Framework Core with transactional atomic SQL locking and raw output bindings.

### XSS Prevention
- All user-supplied fields rendered in table cells, cards, and modal dialogs pass through an `escapeHtml()` sanitization helper in `frontend/js/utils.js`.

---

## 8. Automated Test Suite (34 / 34 Tests Passing)

An end-to-end test suite validates all functional, security, and edge-case requirements:

```powershell
powershell -ExecutionPolicy Bypass -File backend\test_suite.ps1
```

### Test Results
```
========== STARTING TEST SUITE ==========

 [PASS] Auth - Admin Login (admin@company.com)
 [PASS] Auth - Manager Login (manager@company.com)
 [PASS] Auth - Employee Login (employee@company.com)
 [PASS] Auth - Invalid Login (Reject wrong password)
 [PASS] Auth - Unauthorized Request (No Bearer Token)
 [PASS] Lookups - Get Departments
 [PASS] Lookups - Get Roles
 [PASS] Employees - Get All Employees (Paged)
 [PASS] Employees - Get Employee by ID (Admin sees unmasked PII)
 [PASS] Employees - Get Personal Details (Employee sees MASKED PII)
 [PASS] Employees - Explicit /personal-details endpoint
 [PASS] Search & Filter - Global Search by Name (Search='Rahul')
 [PASS] Search & Filter - Global Search by Department Name (Search='Finance')
 [PASS] Search & Filter - Filter by DepartmentId (Dept=1 / IT)
 [PASS] Search & Filter - Filter by Status (Status='Inactive')
 [PASS] Search & Filter - Filter by Salary Range (500000 to 1000000)
 [PASS] Search & Filter - Combined Filters (Dept=1 + Status='Active' + MinSalary=600000)
 [PASS] Sort & Paging - Sort by FullName ASC vs DESC
 [PASS] Sort & Paging - Pagination page sizes (5, 10, 20)
 [PASS] Validation - Reject Invalid Name (Contains digits)
 [PASS] Validation - Reject Invalid Mobile (9 digits)
 [PASS] Validation - Reject Invalid Aadhaar (unformatted)
 [PASS] Validation - Reject Invalid PAN (wrong format)
 [PASS] Validation - Reject Future Date of Birth
 [PASS] Validation - Reject Negative or Zero Salary
 [PASS] Validation - Reject Duplicate Email
 [PASS] CRUD - Create Employee (Auto Code Generation in Dept 1 / IT)
 [PASS] CRUD - Update Employee (Modify Salary and Address)
 [PASS] Transfer - Department Transfer (From IT Dept 1 to HR Dept 2)
 [PASS] Transfer - Reject Transfer to Same Department
 [PASS] Transfer - Verify Transfer History Audit Log
 [PASS] Deactivate - Reject Non-Admin Deactivate (Employee role gets 403 Forbidden)
 [PASS] Deactivate - Admin Deactivates Employee
 [PASS] Transfer - Reject Transfer of Inactive Employee

========== TEST SUITE COMPLETE ==========

Total Tests: 34 | PASSED: 34 | FAILED: 0
```

---

## 9. Dependencies & Packages (.NET 8)

| Package | Version | Purpose |
|:---|:---|:---|
| `Microsoft.EntityFrameworkCore` | 8.0.0 | Object-Relational Mapping (ORM) |
| `Microsoft.EntityFrameworkCore.SqlServer` | 8.0.0 | SQL Server Database Provider |
| `Microsoft.EntityFrameworkCore.Design` | 8.0.0 | EF Core design-time & migration tools |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | 8.0.0 | JWT Authentication Middleware & token processing |
| `Swashbuckle.AspNetCore` | 6.5.0 | OpenAPI / Swagger specification and interactive UI |
| `BCrypt.Net-Next` | 4.0.3 | Salt-based password hashing |

---

## 10. License & Submission
Developed as part of the IAIP Assignment.
All code, database migrations, tests, and documentation are included in the repository and submission package.
