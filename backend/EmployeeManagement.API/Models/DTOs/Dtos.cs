using System.ComponentModel.DataAnnotations;

namespace EmployeeManagement.API.Models.DTOs;

// ─── Auth ────────────────────────────────────────────────────────────────────

public class LoginRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}

public class LoginResponse
{
    public string Token { get; set; } = string.Empty;
    public string UserRole { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int? EmployeeId { get; set; }
    public DateTime ExpiresAt { get; set; }
}

// ─── Employee ─────────────────────────────────────────────────────────────────

public class CreateEmployeeRequest
{
    [Required(ErrorMessage = "Full name is required.")]
    [RegularExpression(@"^[A-Za-z ]+$", ErrorMessage = "Name must contain alphabets and spaces only.")]
    [MaxLength(150)]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = "Invalid email format.")]
    [MaxLength(200)]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mobile number is required.")]
    [RegularExpression(@"^\d{10}$", ErrorMessage = "Mobile number must be exactly 10 digits.")]
    public string MobileNumber { get; set; } = string.Empty;

    [Required(ErrorMessage = "Gender is required.")]
    [RegularExpression(@"^(Male|Female|Other)$", ErrorMessage = "Gender must be Male, Female, or Other.")]
    public string Gender { get; set; } = string.Empty;

    [Required(ErrorMessage = "Date of birth is required.")]
    public DateOnly DateOfBirth { get; set; }

    [Required(ErrorMessage = "Address is required.")]
    [MaxLength(500)]
    public string Address { get; set; } = string.Empty;

    [Required(ErrorMessage = "Department is required.")]
    public int DepartmentId { get; set; }

    [Required(ErrorMessage = "Role is required.")]
    public int RoleId { get; set; }

    [Required(ErrorMessage = "Joining date is required.")]
    public DateOnly JoiningDate { get; set; }

    [Required(ErrorMessage = "Annual salary is required.")]
    [Range(1, double.MaxValue, ErrorMessage = "Salary must be greater than zero.")]
    public decimal AnnualSalary { get; set; }

    // Sensitive
    [Required(ErrorMessage = "Aadhaar number is required.")]
    [RegularExpression(@"^\d{4}-\d{4}-\d{4}$", ErrorMessage = "Aadhaar must be in format XXXX-XXXX-XXXX.")]
    public string AadhaarNumber { get; set; } = string.Empty;

    [Required(ErrorMessage = "PAN number is required.")]
    [RegularExpression(@"^[A-Z]{5}[0-9]{4}[A-Z]$", ErrorMessage = "PAN must be in format ABCDE1234F.")]
    public string PANNumber { get; set; } = string.Empty;
}

public class UpdateEmployeeRequest : CreateEmployeeRequest
{
    public string EmployeeStatus { get; set; } = "Active";
}

public class EmployeeListDto
{
    public int EmployeeId { get; set; }
    public string EmployeeCode { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public string Gender { get; set; } = string.Empty;
    public string DepartmentName { get; set; } = string.Empty;
    public string RoleName { get; set; } = string.Empty;
    public decimal AnnualSalary { get; set; }
    public string EmployeeStatus { get; set; } = string.Empty;
    public DateOnly JoiningDate { get; set; }
}

public class EmployeeDetailDto : EmployeeListDto
{
    public DateOnly DateOfBirth { get; set; }
    public string Address { get; set; } = string.Empty;
    public int DepartmentId { get; set; }
    public int RoleId { get; set; }
    public string AadhaarNumber { get; set; } = string.Empty;
    public string PANNumber { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

// ─── Transfer ─────────────────────────────────────────────────────────────────

public class TransferEmployeeRequest
{
    [Required]
    public int EmployeeId { get; set; }

    [Required]
    public int NewDepartmentId { get; set; }

    [Required]
    public int NewRoleId { get; set; }

    [Required]
    public DateOnly TransferDate { get; set; }

    [Required(ErrorMessage = "Transfer reason is required.")]
    [MaxLength(1000)]
    public string TransferReason { get; set; } = string.Empty;
}

public class TransferHistoryDto
{
    public int TransferId { get; set; }
    public string EmployeeFullName { get; set; } = string.Empty;
    public string OldDepartmentName { get; set; } = string.Empty;
    public string NewDepartmentName { get; set; } = string.Empty;
    public string OldEmployeeCode { get; set; } = string.Empty;
    public string NewEmployeeCode { get; set; } = string.Empty;
    public string OldRoleName { get; set; } = string.Empty;
    public string NewRoleName { get; set; } = string.Empty;
    public DateOnly TransferDate { get; set; }
    public string TransferReason { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

// ─── Pagination / Filter ──────────────────────────────────────────────────────

public class EmployeeFilterRequest
{
    public string? Search { get; set; }
    public int? DepartmentId { get; set; }
    public int? RoleId { get; set; }
    public string? Status { get; set; }
    public string? Gender { get; set; }
    public DateOnly? JoiningDateFrom { get; set; }
    public DateOnly? JoiningDateTo { get; set; }
    public decimal? MinSalary { get; set; }
    public decimal? MaxSalary { get; set; }
    public string SortBy { get; set; } = "EmployeeCode";
    public string SortDirection { get; set; } = "ASC";
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}

public class PagedResult<T>
{
    public IEnumerable<T> Data { get; set; } = Enumerable.Empty<T>();
    public int TotalCount { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
}

// ─── Common ───────────────────────────────────────────────────────────────────

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }

    public static ApiResponse<T> Ok(T data, string message = "Success")
        => new() { Success = true, Message = message, Data = data };

    public static ApiResponse<T> Fail(string message)
        => new() { Success = false, Message = message };
}

public class DepartmentDto
{
    public int DepartmentId { get; set; }
    public string DepartmentName { get; set; } = string.Empty;
    public string DepartmentCode { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class RoleDto
{
    public int RoleId { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public int? DepartmentId { get; set; }
    public string? Description { get; set; }
}
