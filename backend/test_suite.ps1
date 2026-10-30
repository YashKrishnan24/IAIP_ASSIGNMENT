# ============================================================
#  Comprehensive Feature Verification & Test Suite
# ============================================================

$baseUrl = "http://localhost:5000/api"
$testResults = @()

function Run-Test {
    param(
        [string]$Category,
        [string]$TestName,
        [scriptblock]$Action
    )
    try {
        $result = & $Action
        $script:testResults += [PSCustomObject]@{
            Category = $Category
            Test     = $TestName
            Status   = "PASSED"
            Details  = $result
        }
        Write-Host " [PASS] $Category - $TestName" -ForegroundColor Green
    }
    catch {
        $script:testResults += [PSCustomObject]@{
            Category = $Category
            Test     = $TestName
            Status   = "FAILED"
            Details  = $_.Exception.Message
        }
        Write-Host " [FAIL] $Category - $TestName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n========== STARTING TEST SUITE ==========`n" -ForegroundColor Cyan

# ─── 1. Authentication Tests ───
$adminToken = ""
$managerToken = ""
$employeeToken = ""

Run-Test "Auth" "Admin Login (admin@company.com)" {
    $res = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body '{"email":"admin@company.com","password":"Admin@123"}' -ContentType "application/json"
    if ($res.success -ne $true -or $res.data.userRole -ne "Admin") { throw "Expected Admin role" }
    $script:adminToken = $res.data.token
    "Role: $($res.data.userRole), Token received"
}

Run-Test "Auth" "Manager Login (manager@company.com)" {
    $res = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body '{"email":"manager@company.com","password":"Manager@123"}' -ContentType "application/json"
    if ($res.success -ne $true -or $res.data.userRole -ne "Manager") { throw "Expected Manager role" }
    $script:managerToken = $res.data.token
    "Role: $($res.data.userRole), Token received"
}

Run-Test "Auth" "Employee Login (employee@company.com)" {
    $res = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body '{"email":"employee@company.com","password":"Employee@123"}' -ContentType "application/json"
    if ($res.success -ne $true -or $res.data.userRole -ne "Employee") { throw "Expected Employee role" }
    $script:employeeToken = $res.data.token
    "Role: $($res.data.userRole), Token received"
}

Run-Test "Auth" "Invalid Login (Reject wrong password)" {
    try {
        Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body '{"email":"admin@company.com","password":"WrongPassword"}' -ContentType "application/json"
        throw "Should have failed with 401"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) {
            "Correctly rejected with 401 Unauthorized"
        } else { throw $_ }
    }
}

Run-Test "Auth" "Unauthorized Request (No Bearer Token)" {
    try {
        Invoke-RestMethod -Uri "$baseUrl/employees" -Method Get
        throw "Should have failed with 401"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) {
            "Correctly blocked with 401 Unauthorized"
        } else { throw $_ }
    }
}

# ─── 2. Lookups Tests ───
Run-Test "Lookups" "Get Departments" {
    $res = Invoke-RestMethod -Uri "$baseUrl/departments" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($res.data.Count -lt 5) { throw "Expected at least 5 departments" }
    "Found $($res.data.Count) departments ($(($res.data | Select-Object -ExpandProperty departmentCode) -join ', '))"
}

Run-Test "Lookups" "Get Roles" {
    $res = Invoke-RestMethod -Uri "$baseUrl/roles" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($res.data.Count -lt 3) { throw "Expected at least 3 roles" }
    "Found $($res.data.Count) roles"
}

# ─── 3. Employees Read & Details ───
Run-Test "Employees" "Get All Employees (Paged)" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees?pageNumber=1&pageSize=10" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($res.data.totalCount -lt 20) { throw "Expected at least 20 employees" }
    "Total Count: $($res.data.totalCount), Returned: $($res.data.data.Count)"
}

Run-Test "Employees" "Get Employee by ID (Admin sees unmasked PII)" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees/1" -Headers @{ Authorization = "Bearer $adminToken" }
    $emp = $res.data
    if ($emp.aadhaarNumber -like "*X*" -or $emp.aadhaarNumber -like "*\**") { throw "Admin should see unmasked Aadhaar" }
    "Employee: $($emp.fullName), Code: $($emp.employeeCode), Aadhaar: $($emp.aadhaarNumber), PAN: $($emp.panNumber)"
}

Run-Test "Employees" "Get Personal Details (Employee sees MASKED PII)" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees/1" -Headers @{ Authorization = "Bearer $employeeToken" }
    $emp = $res.data
    if ($emp.aadhaarNumber -notlike "****-****-*") { throw "Employee role should see masked Aadhaar, got $($emp.aadhaarNumber)" }
    "Masked Aadhaar: $($emp.aadhaarNumber), Masked PAN: $($emp.panNumber)"
}

Run-Test "Employees" "Explicit /personal-details endpoint" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees/1/personal-details" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($res.data.employeeId -ne 1) { throw "Expected employeeId 1" }
    "Endpoint accessible and returned data for $($res.data.fullName)"
}

# ─── 4. Search, Filter, Sort, Pagination ───
Run-Test "Search & Filter" "Global Search by Name (Search='Rahul')" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees?search=Rahul" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($res.data.totalCount -eq 0) { throw "Expected results for 'Rahul'" }
    "Matches found: $($res.data.totalCount)"
}

Run-Test "Search & Filter" "Global Search by Department Name (Search='Finance')" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees?search=Finance" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($res.data.totalCount -eq 0) { throw "Expected results for 'Finance'" }
    "Matches found: $($res.data.totalCount)"
}

Run-Test "Search & Filter" "Filter by DepartmentId (Dept=1 / IT)" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees?departmentId=1" -Headers @{ Authorization = "Bearer $adminToken" }
    foreach ($e in $res.data.data) {
        if ($e.departmentName -ne "Information Technology") { throw "Non-IT employee returned" }
    }
    "Found $($res.data.totalCount) IT employees"
}

Run-Test "Search & Filter" "Filter by Status (Status='Inactive')" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees?status=Inactive" -Headers @{ Authorization = "Bearer $adminToken" }
    foreach ($e in $res.data.data) {
        if ($e.employeeStatus -ne "Inactive") { throw "Active employee returned" }
    }
    "Found $($res.data.totalCount) Inactive employees"
}

Run-Test "Search & Filter" "Filter by Salary Range (500000 to 1000000)" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees?minSalary=500000&maxSalary=1000000" -Headers @{ Authorization = "Bearer $adminToken" }
    foreach ($e in $res.data.data) {
        if ($e.annualSalary -lt 500000 -or $e.annualSalary -ge 1000000) { throw "Salary out of range: $($e.annualSalary)" }
    }
    "Found $($res.data.totalCount) employees in 5L-10L bracket"
}

Run-Test "Search & Filter" "Combined Filters (Dept=1 + Status='Active' + MinSalary=600000)" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees?departmentId=1&status=Active&minSalary=600000" -Headers @{ Authorization = "Bearer $adminToken" }
    foreach ($e in $res.data.data) {
        if ($e.departmentName -ne "Information Technology" -or $e.employeeStatus -ne "Active" -or $e.annualSalary -lt 600000) {
            throw "Combined filter mismatch"
        }
    }
    "Found $($res.data.totalCount) matching combined criteria"
}

Run-Test "Sort & Paging" "Sort by FullName ASC vs DESC" {
    $asc = Invoke-RestMethod -Uri "$baseUrl/employees?sortBy=FullName&sortDirection=ASC&pageSize=2" -Headers @{ Authorization = "Bearer $adminToken" }
    $desc = Invoke-RestMethod -Uri "$baseUrl/employees?sortBy=FullName&sortDirection=DESC&pageSize=2" -Headers @{ Authorization = "Bearer $adminToken" }
    $firstAsc = $asc.data.data[0].fullName
    $firstDesc = $desc.data.data[0].fullName
    if ($firstAsc -eq $firstDesc) { throw "Sort ASC and DESC produced identical first item: $firstAsc" }
    "ASC first: '$firstAsc', DESC first: '$firstDesc'"
}

Run-Test "Sort & Paging" "Pagination page sizes (5, 10, 20)" {
    $p5 = Invoke-RestMethod -Uri "$baseUrl/employees?pageSize=5&pageNumber=1" -Headers @{ Authorization = "Bearer $adminToken" }
    $p10 = Invoke-RestMethod -Uri "$baseUrl/employees?pageSize=10&pageNumber=1" -Headers @{ Authorization = "Bearer $adminToken" }
    $p20 = Invoke-RestMethod -Uri "$baseUrl/employees?pageSize=20&pageNumber=1" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($p5.data.data.Count -ne 5 -or $p10.data.data.Count -ne 10 -or $p20.data.data.Count -ne 20) {
        throw "PageSize constraint mismatch"
    }
    "Verified 5 records, 10 records, and 20 records returned correctly"
}

# ─── 5. Validations (Negative Testing) ───
Run-Test "Validation" "Reject Invalid Name (Contains digits)" {
    try {
        $body = @{
            fullName = "John123"
            email = "john.valid@company.com"
            mobileNumber = "9998887776"
            gender = "Male"
            dateOfBirth = "1995-01-01"
            address = "Test address"
            departmentId = 1
            roleId = 1
            joiningDate = "2023-01-01"
            annualSalary = 500000
            aadhaarNumber = "9999-8888-7777"
            panNumber = "ABCDE1234F"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/employees" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
        throw "Should have rejected name with digits"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
            "Correctly rejected with 400 Bad Request"
        } else { throw $_ }
    }
}

Run-Test "Validation" "Reject Invalid Mobile (9 digits)" {
    try {
        $body = @{
            fullName = "John Doe"
            email = "john.valid@company.com"
            mobileNumber = "999888777" # 9 digits
            gender = "Male"
            dateOfBirth = "1995-01-01"
            address = "Test address"
            departmentId = 1
            roleId = 1
            joiningDate = "2023-01-01"
            annualSalary = 500000
            aadhaarNumber = "9999-8888-7777"
            panNumber = "ABCDE1234F"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/employees" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
        throw "Should have rejected 9 digit mobile"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
            "Correctly rejected with 400 Bad Request"
        } else { throw $_ }
    }
}

Run-Test "Validation" "Reject Invalid Aadhaar (unformatted)" {
    try {
        $body = @{
            fullName = "John Doe"
            email = "john.valid@company.com"
            mobileNumber = "9998887776"
            gender = "Male"
            dateOfBirth = "1995-01-01"
            address = "Test address"
            departmentId = 1
            roleId = 1
            joiningDate = "2023-01-01"
            annualSalary = 500000
            aadhaarNumber = "999988887777" # missing hyphens
            panNumber = "ABCDE1234F"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/employees" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
        throw "Should have rejected Aadhaar without hyphens"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
            "Correctly rejected with 400 Bad Request"
        } else { throw $_ }
    }
}

Run-Test "Validation" "Reject Invalid PAN (wrong format)" {
    try {
        $body = @{
            fullName = "John Doe"
            email = "john.valid@company.com"
            mobileNumber = "9998887776"
            gender = "Male"
            dateOfBirth = "1995-01-01"
            address = "Test address"
            departmentId = 1
            roleId = 1
            joiningDate = "2023-01-01"
            annualSalary = 500000
            aadhaarNumber = "9999-8888-7777"
            panNumber = "12345ABCDE" # digits first
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/employees" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
        throw "Should have rejected invalid PAN"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
            "Correctly rejected with 400 Bad Request"
        } else { throw $_ }
    }
}

Run-Test "Validation" "Reject Future Date of Birth" {
    try {
        $futureDob = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")
        $body = @{
            fullName = "John Doe"
            email = "john.valid@company.com"
            mobileNumber = "9998887776"
            gender = "Male"
            dateOfBirth = $futureDob
            address = "Test address"
            departmentId = 1
            roleId = 1
            joiningDate = "2023-01-01"
            annualSalary = 500000
            aadhaarNumber = "9999-8888-7777"
            panNumber = "ABCDE1234F"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/employees" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
        throw "Should have rejected future DOB"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Conflict -or $_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
            "Correctly rejected future DOB"
        } else { throw $_ }
    }
}

Run-Test "Validation" "Reject Negative or Zero Salary" {
    try {
        $body = @{
            fullName = "John Doe"
            email = "john.valid@company.com"
            mobileNumber = "9998887776"
            gender = "Male"
            dateOfBirth = "1995-01-01"
            address = "Test address"
            departmentId = 1
            roleId = 1
            joiningDate = "2023-01-01"
            annualSalary = 0 # Invalid
            aadhaarNumber = "9999-8888-7777"
            panNumber = "ABCDE1234F"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/employees" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
        throw "Should have rejected zero salary"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
            "Correctly rejected with 400 Bad Request"
        } else { throw $_ }
    }
}

Run-Test "Validation" "Reject Duplicate Email" {
    try {
        $body = @{
            fullName = "Another Rahul"
            email = "rahul.sharma@company.com" # Already exists
            mobileNumber = "9998887776"
            gender = "Male"
            dateOfBirth = "1995-01-01"
            address = "Test address"
            departmentId = 1
            roleId = 1
            joiningDate = "2023-01-01"
            annualSalary = 500000
            aadhaarNumber = "9999-8888-7777"
            panNumber = "ABCDE1234F"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/employees" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
        throw "Should have rejected duplicate email"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Conflict) {
            "Correctly rejected duplicate with 409 Conflict"
        } else { throw $_ }
    }
}

# ─── 6. Full CRUD Lifecycle & Department Code Auto-Generation ───
$createdEmpId = 0
$createdEmpCode = ""

Run-Test "CRUD" "Create Employee (Auto Code Generation in Dept 1 / IT)" {
    $randNum = Get-Random -Minimum 1000 -Maximum 9999
    $body = @{
        fullName = "Aarav Gupta"
        email = "aarav.test$randNum@company.com"
        mobileNumber = "981234$randNum"
        gender = "Male"
        dateOfBirth = "1996-05-15"
        address = "100 Tech Park, Whitefield, Bengaluru"
        departmentId = 1 # IT
        roleId = 1       # Software Engineer
        joiningDate = "2024-01-15"
        annualSalary = 750000
        aadhaarNumber = "5555-4444-$randNum"
        panNumber = "AARAV$randNum" + "A"
    } | ConvertTo-Json

    $res = Invoke-RestMethod -Uri "$baseUrl/employees" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($res.success -ne $true) { throw "Creation failed" }
    $script:createdEmpId = $res.data.employeeId
    $script:createdEmpCode = $res.data.employeeCode
    if ($createdEmpCode -notlike "I*") { throw "Expected code starting with 'I' for IT dept, got $createdEmpCode" }
    "Created Employee ID: $createdEmpId, Auto-Generated Code: $createdEmpCode"
}

Run-Test "CRUD" "Update Employee (Modify Salary and Address)" {
    $body = @{
        fullName = "Aarav Gupta"
        email = "aarav.updated$createdEmpId@company.com"
        mobileNumber = "9812345678"
        gender = "Male"
        dateOfBirth = "1996-05-15"
        address = "200 Silicon Avenue, Electronic City, Bengaluru"
        departmentId = 1
        roleId = 2 # Senior Software Engineer
        joiningDate = "2024-01-15"
        annualSalary = 950000 # Increased
        employeeStatus = "Active"
        aadhaarNumber = "5555-4444-1234"
        panNumber = "AARAV1234A"
    } | ConvertTo-Json

    $res = Invoke-RestMethod -Uri "$baseUrl/employees/$createdEmpId" -Method Put -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($res.data.annualSalary -ne 950000) { throw "Salary not updated" }
    "Updated Salary: $($res.data.annualSalary), Role: $($res.data.roleName)"
}

# ─── 7. Department Transfer Functionality ───
$transferredNewCode = ""

Run-Test "Transfer" "Department Transfer (From IT Dept 1 to HR Dept 2)" {
    $body = @{
        employeeId = $createdEmpId
        newDepartmentId = 2 # HR
        newRoleId = 4       # HR Executive
        transferDate = (Get-Date).ToString("yyyy-MM-dd")
        transferReason = "Transferred to HR operations to lead technical recruitment initiative."
    } | ConvertTo-Json

    $res = Invoke-RestMethod -Uri "$baseUrl/employees/transfer" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $managerToken" }
    if ($res.success -ne $true) { throw "Transfer failed" }
    $script:transferredNewCode = $res.data.newEmployeeCode
    if ($transferredNewCode -notlike "H*") { throw "Expected code starting with 'H' for HR, got $transferredNewCode" }

    # Verify employee record has new code and department
    $check = Invoke-RestMethod -Uri "$baseUrl/employees/$createdEmpId" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($check.data.employeeCode -ne $transferredNewCode -or $check.data.departmentName -ne "Human Resources") {
        throw "Employee record did not reflect new code or department"
    }
    "Transferred from $createdEmpCode -> $transferredNewCode (Dept: $($check.data.departmentName))"
}

Run-Test "Transfer" "Reject Transfer to Same Department" {
    try {
        $body = @{
            employeeId = $createdEmpId
            newDepartmentId = 2 # Already in HR!
            newRoleId = 5
            transferDate = (Get-Date).ToString("yyyy-MM-dd")
            transferReason = "Same department transfer attempt"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/employees/transfer" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $managerToken" }
        throw "Should have rejected same department transfer"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
            "Correctly rejected same department transfer with 400 Bad Request"
        } else { throw $_ }
    }
}

Run-Test "Transfer" "Verify Transfer History Audit Log" {
    $history = Invoke-RestMethod -Uri "$baseUrl/employees/$createdEmpId/transfer-history" -Headers @{ Authorization = "Bearer $adminToken" }
    if ($history.data.Count -eq 0) { throw "Expected transfer history record" }
    $latest = $history.data[0]
    "Audit Log Found: Old Code '$($latest.oldEmployeeCode)' -> New Code '$($latest.newEmployeeCode)', Reason: '$($latest.transferReason)'"
}

# ─── 8. Deactivate (Soft-Delete) & Role-Based Authorization ───
Run-Test "Deactivate" "Reject Non-Admin Deactivate (Employee role gets 403 Forbidden)" {
    try {
        Invoke-RestMethod -Uri "$baseUrl/employees/$createdEmpId" -Method Delete -Headers @{ Authorization = "Bearer $employeeToken" }
        throw "Should have blocked employee role with 403"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden) {
            "Correctly blocked with 403 Forbidden"
        } else { throw $_ }
    }
}

Run-Test "Deactivate" "Admin Deactivates Employee" {
    $res = Invoke-RestMethod -Uri "$baseUrl/employees/$createdEmpId" -Method Delete -Headers @{ Authorization = "Bearer $adminToken" }
    if ($res.success -ne $true) { throw "Deactivation call failed" }
    
    # Check status is now Inactive
    $emp = (Invoke-RestMethod -Uri "$baseUrl/employees/$createdEmpId" -Headers @{ Authorization = "Bearer $adminToken" }).data
    if ($emp.employeeStatus -ne "Inactive") { throw "Employee status should be Inactive, got $($emp.employeeStatus)" }
    "Employee status successfully updated to Inactive"
}

Run-Test "Transfer" "Reject Transfer of Inactive Employee" {
    try {
        $body = @{
            employeeId = $createdEmpId # Currently Inactive!
            newDepartmentId = 3        # Finance
            newRoleId = 6
            transferDate = (Get-Date).ToString("yyyy-MM-dd")
            transferReason = "Attempt transfer inactive employee"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/employees/transfer" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $adminToken" }
        throw "Should have rejected inactive employee transfer"
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
            "Correctly rejected inactive employee transfer"
        } else { throw $_ }
    }
}

Write-Host "`n========== TEST SUITE COMPLETE ==========`n" -ForegroundColor Cyan
$passed = ($testResults | Where-Object { $_.Status -eq "PASSED" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAILED" }).Count
Write-Host "Total Tests: $($testResults.Count) | PASSED: $passed | FAILED: $failed`n" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

$testResults | Format-Table -Property Category, Test, Status, Details -AutoSize
