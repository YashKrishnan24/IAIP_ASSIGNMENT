using EmployeeManagement.API.Models;
using EmployeeManagement.API.Models.DTOs;
using Microsoft.EntityFrameworkCore;

namespace EmployeeManagement.API.Services;

public interface IEmployeeService
{
    Task<PagedResult<EmployeeListDto>> GetEmployeesAsync(EmployeeFilterRequest filter);
    Task<EmployeeDetailDto?> GetEmployeeByIdAsync(int id);
    Task<EmployeeDetailDto> CreateEmployeeAsync(CreateEmployeeRequest request);
    Task<EmployeeDetailDto> UpdateEmployeeAsync(int id, UpdateEmployeeRequest request);
    Task<bool> DeactivateEmployeeAsync(int id);
    Task<string> TransferEmployeeAsync(TransferEmployeeRequest request, int? transferredByUserId);
    Task<IEnumerable<TransferHistoryDto>> GetTransferHistoryAsync(int employeeId);
}

public class EmployeeService : IEmployeeService
{
    private readonly Data.AppDbContext _ctx;

    public EmployeeService(Data.AppDbContext ctx) => _ctx = ctx;

    // ─────────────────────────────────────────────────────────────────────────
    // GET (paged, filtered, sorted)
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<PagedResult<EmployeeListDto>> GetEmployeesAsync(EmployeeFilterRequest f)
    {
        var query = _ctx.Employees
            .Include(e => e.Department)
            .Include(e => e.Role)
            .AsNoTracking()
            .AsQueryable();

        // Global search (exclude Aadhaar/PAN)
        if (!string.IsNullOrWhiteSpace(f.Search))
        {
            var s = f.Search.ToLower();
            query = query.Where(e =>
                e.EmployeeCode.ToLower().Contains(s) ||
                e.FullName.ToLower().Contains(s) ||
                e.Email.ToLower().Contains(s) ||
                e.MobileNumber.Contains(s) ||
                e.Department!.DepartmentName.ToLower().Contains(s) ||
                e.Role!.RoleName.ToLower().Contains(s) ||
                e.Address.ToLower().Contains(s) ||
                e.EmployeeStatus.ToLower().Contains(s) ||
                e.Gender.ToLower().Contains(s));
        }

        if (f.DepartmentId.HasValue)   query = query.Where(e => e.DepartmentId == f.DepartmentId);
        if (f.RoleId.HasValue)         query = query.Where(e => e.RoleId == f.RoleId);
        if (!string.IsNullOrEmpty(f.Status)) query = query.Where(e => e.EmployeeStatus == f.Status);
        if (!string.IsNullOrEmpty(f.Gender)) query = query.Where(e => e.Gender == f.Gender);
        if (f.JoiningDateFrom.HasValue) query = query.Where(e => e.JoiningDate >= f.JoiningDateFrom);
        if (f.JoiningDateTo.HasValue)   query = query.Where(e => e.JoiningDate <= f.JoiningDateTo);
        if (f.MinSalary.HasValue)       query = query.Where(e => e.AnnualSalary >= f.MinSalary);
        if (f.MaxSalary.HasValue)       query = query.Where(e => e.AnnualSalary < f.MaxSalary);

        // Sorting
        query = (f.SortBy, f.SortDirection?.ToUpper()) switch
        {
            ("FullName",       "DESC") => query.OrderByDescending(e => e.FullName),
            ("FullName",       _     ) => query.OrderBy(e => e.FullName),
            ("Email",          "DESC") => query.OrderByDescending(e => e.Email),
            ("Email",          _     ) => query.OrderBy(e => e.Email),
            ("DepartmentName", "DESC") => query.OrderByDescending(e => e.Department!.DepartmentName),
            ("DepartmentName", _     ) => query.OrderBy(e => e.Department!.DepartmentName),
            ("RoleName",       "DESC") => query.OrderByDescending(e => e.Role!.RoleName),
            ("RoleName",       _     ) => query.OrderBy(e => e.Role!.RoleName),
            ("JoiningDate",    "DESC") => query.OrderByDescending(e => e.JoiningDate),
            ("JoiningDate",    _     ) => query.OrderBy(e => e.JoiningDate),
            ("AnnualSalary",   "DESC") => query.OrderByDescending(e => e.AnnualSalary),
            ("AnnualSalary",   _     ) => query.OrderBy(e => e.AnnualSalary),
            ("EmployeeStatus", "DESC") => query.OrderByDescending(e => e.EmployeeStatus),
            ("EmployeeStatus", _     ) => query.OrderBy(e => e.EmployeeStatus),
            ("EmployeeCode",   "DESC") => query.OrderByDescending(e => e.EmployeeCode),
            _                          => query.OrderBy(e => e.EmployeeCode),
        };

        var total = await query.CountAsync();

        var pageSize   = Math.Clamp(f.PageSize, 1, 100);
        var pageNumber = Math.Max(f.PageNumber, 1);

        var data = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(e => new EmployeeListDto
            {
                EmployeeId     = e.EmployeeId,
                EmployeeCode   = e.EmployeeCode,
                FullName       = e.FullName,
                Email          = e.Email,
                MobileNumber   = e.MobileNumber,
                Gender         = e.Gender,
                DepartmentName = e.Department!.DepartmentName,
                RoleName       = e.Role!.RoleName,
                AnnualSalary   = e.AnnualSalary,
                EmployeeStatus = e.EmployeeStatus,
                JoiningDate    = e.JoiningDate,
            })
            .ToListAsync();

        return new PagedResult<EmployeeListDto>
        {
            Data        = data,
            TotalCount  = total,
            PageNumber  = pageNumber,
            PageSize    = pageSize,
        };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET by ID (with PII)
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<EmployeeDetailDto?> GetEmployeeByIdAsync(int id)
    {
        var e = await _ctx.Employees
            .Include(x => x.Department)
            .Include(x => x.Role)
            .Include(x => x.PersonalDetail)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.EmployeeId == id);

        if (e is null) return null;

        return MapToDetail(e);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CREATE
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<EmployeeDetailDto> CreateEmployeeAsync(CreateEmployeeRequest req)
    {
        // Duplicate checks
        if (await _ctx.Employees.AnyAsync(e => e.Email == req.Email))
            throw new InvalidOperationException("Email address is already registered.");

        if (await _ctx.EmployeePersonalDetails.AnyAsync(p => p.AadhaarNumber == req.AadhaarNumber))
            throw new InvalidOperationException("Aadhaar number is already registered.");

        if (await _ctx.EmployeePersonalDetails.AnyAsync(p => p.PANNumber == req.PANNumber))
            throw new InvalidOperationException("PAN number is already registered.");

        // Date of birth validation
        if (req.DateOfBirth >= DateOnly.FromDateTime(DateTime.Today))
            throw new InvalidOperationException("Date of birth cannot be today or a future date.");

        // Generate employee code
        var code = await GenerateCodeAsync(req.DepartmentId);

        using var tx = await _ctx.Database.BeginTransactionAsync();
        try
        {
            var emp = new Employee
            {
                EmployeeCode   = code,
                FullName       = req.FullName,
                Email          = req.Email,
                MobileNumber   = req.MobileNumber,
                Gender         = req.Gender,
                DateOfBirth    = req.DateOfBirth,
                Address        = req.Address,
                DepartmentId   = req.DepartmentId,
                RoleId         = req.RoleId,
                JoiningDate    = req.JoiningDate,
                AnnualSalary   = req.AnnualSalary,
                EmployeeStatus = "Active",
            };

            _ctx.Employees.Add(emp);
            await _ctx.SaveChangesAsync();

            _ctx.EmployeePersonalDetails.Add(new EmployeePersonalDetail
            {
                EmployeeId    = emp.EmployeeId,
                AadhaarNumber = req.AadhaarNumber,
                PANNumber     = req.PANNumber,
            });
            await _ctx.SaveChangesAsync();
            await tx.CommitAsync();

            return (await GetEmployeeByIdAsync(emp.EmployeeId))!;
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UPDATE
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<EmployeeDetailDto> UpdateEmployeeAsync(int id, UpdateEmployeeRequest req)
    {
        var emp = await _ctx.Employees
            .Include(e => e.PersonalDetail)
            .FirstOrDefaultAsync(e => e.EmployeeId == id)
            ?? throw new KeyNotFoundException("Employee not found.");

        // Duplicate email check (exclude self)
        if (await _ctx.Employees.AnyAsync(e => e.Email == req.Email && e.EmployeeId != id))
            throw new InvalidOperationException("Email address is already in use.");

        if (await _ctx.EmployeePersonalDetails.AnyAsync(p => p.AadhaarNumber == req.AadhaarNumber && p.EmployeeId != id))
            throw new InvalidOperationException("Aadhaar number is already registered.");

        if (await _ctx.EmployeePersonalDetails.AnyAsync(p => p.PANNumber == req.PANNumber && p.EmployeeId != id))
            throw new InvalidOperationException("PAN number is already registered.");

        if (req.DateOfBirth >= DateOnly.FromDateTime(DateTime.Today))
            throw new InvalidOperationException("Date of birth cannot be today or a future date.");

        emp.FullName       = req.FullName;
        emp.Email          = req.Email;
        emp.MobileNumber   = req.MobileNumber;
        emp.Gender         = req.Gender;
        emp.DateOfBirth    = req.DateOfBirth;
        emp.Address        = req.Address;
        emp.RoleId         = req.RoleId;
        emp.JoiningDate    = req.JoiningDate;
        emp.AnnualSalary   = req.AnnualSalary;
        emp.EmployeeStatus = req.EmployeeStatus;
        emp.UpdatedAt      = DateTime.UtcNow;

        if (emp.PersonalDetail is not null)
        {
            emp.PersonalDetail.AadhaarNumber = req.AadhaarNumber;
            emp.PersonalDetail.PANNumber     = req.PANNumber;
            emp.PersonalDetail.UpdatedAt     = DateTime.UtcNow;
        }

        await _ctx.SaveChangesAsync();
        return (await GetEmployeeByIdAsync(id))!;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DEACTIVATE
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<bool> DeactivateEmployeeAsync(int id)
    {
        var emp = await _ctx.Employees.FindAsync(id);
        if (emp is null) return false;

        emp.EmployeeStatus = "Inactive";
        emp.UpdatedAt      = DateTime.UtcNow;
        await _ctx.SaveChangesAsync();
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TRANSFER
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<string> TransferEmployeeAsync(TransferEmployeeRequest req, int? transferredByUserId)
    {
        var emp = await _ctx.Employees.FindAsync(req.EmployeeId)
            ?? throw new KeyNotFoundException("Employee not found.");

        if (emp.EmployeeStatus != "Active")
            throw new InvalidOperationException("Cannot transfer an inactive employee.");

        if (emp.DepartmentId == req.NewDepartmentId)
            throw new InvalidOperationException("Employee is already in the target department.");

        var newCode = await GenerateCodeAsync(req.NewDepartmentId);

        using var tx = await _ctx.Database.BeginTransactionAsync();
        try
        {
            var history = new EmployeeTransferHistory
            {
                EmployeeId       = emp.EmployeeId,
                OldDepartmentId  = emp.DepartmentId,
                NewDepartmentId  = req.NewDepartmentId,
                OldEmployeeCode  = emp.EmployeeCode,
                NewEmployeeCode  = newCode,
                OldRoleId        = emp.RoleId,
                NewRoleId        = req.NewRoleId,
                TransferDate     = req.TransferDate,
                TransferReason   = req.TransferReason,
                TransferredBy    = transferredByUserId,
            };

            emp.DepartmentId = req.NewDepartmentId;
            emp.RoleId       = req.NewRoleId;
            emp.EmployeeCode = newCode;
            emp.UpdatedAt    = DateTime.UtcNow;

            _ctx.EmployeeTransferHistories.Add(history);
            await _ctx.SaveChangesAsync();
            await tx.CommitAsync();

            return newCode;
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TRANSFER HISTORY
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<IEnumerable<TransferHistoryDto>> GetTransferHistoryAsync(int employeeId)
    {
        return await _ctx.EmployeeTransferHistories
            .Include(h => h.Employee)
            .Include(h => h.OldDepartment)
            .Include(h => h.NewDepartment)
            .Include(h => h.OldRole)
            .Include(h => h.NewRole)
            .Where(h => h.EmployeeId == employeeId)
            .OrderByDescending(h => h.TransferDate)
            .AsNoTracking()
            .Select(h => new TransferHistoryDto
            {
                TransferId        = h.TransferId,
                EmployeeFullName  = h.Employee!.FullName,
                OldDepartmentName = h.OldDepartment!.DepartmentName,
                NewDepartmentName = h.NewDepartment!.DepartmentName,
                OldEmployeeCode   = h.OldEmployeeCode,
                NewEmployeeCode   = h.NewEmployeeCode,
                OldRoleName       = h.OldRole!.RoleName,
                NewRoleName       = h.NewRole!.RoleName,
                TransferDate      = h.TransferDate,
                TransferReason    = h.TransferReason,
                CreatedAt         = h.CreatedAt,
            })
            .ToListAsync();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────
    private async Task<string> GenerateCodeAsync(int departmentId)
    {
        var dept = await _ctx.Departments.FindAsync(departmentId)
            ?? throw new KeyNotFoundException("Department not found.");

        var seq = await _ctx.EmployeeCodeSequences.FirstOrDefaultAsync(s => s.DepartmentId == departmentId)
            ?? throw new InvalidOperationException("Code sequence not initialised for department.");

        seq.LastSequence++;
        seq.UpdatedAt = DateTime.UtcNow;
        // Will be saved as part of the outer transaction

        return $"{dept.DepartmentCode}{seq.LastSequence:D4}";
    }

    private static EmployeeDetailDto MapToDetail(Employee e) => new()
    {
        EmployeeId     = e.EmployeeId,
        EmployeeCode   = e.EmployeeCode,
        FullName       = e.FullName,
        Email          = e.Email,
        MobileNumber   = e.MobileNumber,
        Gender         = e.Gender,
        DateOfBirth    = e.DateOfBirth,
        Address        = e.Address,
        DepartmentId   = e.DepartmentId,
        DepartmentName = e.Department?.DepartmentName ?? "",
        RoleId         = e.RoleId,
        RoleName       = e.Role?.RoleName ?? "",
        JoiningDate    = e.JoiningDate,
        AnnualSalary   = e.AnnualSalary,
        EmployeeStatus = e.EmployeeStatus,
        AadhaarNumber  = e.PersonalDetail?.AadhaarNumber ?? "",
        PANNumber      = e.PersonalDetail?.PANNumber ?? "",
        CreatedAt      = e.CreatedAt,
        UpdatedAt      = e.UpdatedAt,
    };
}
