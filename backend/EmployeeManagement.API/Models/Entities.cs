using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EmployeeManagement.API.Models;

public class Department
{
    [Key]
    public int DepartmentId { get; set; }

    [Required, MaxLength(100)]
    public string DepartmentName { get; set; } = string.Empty;

    [Required, MaxLength(1)]
    public string DepartmentCode { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Description { get; set; }

    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ICollection<Employee> Employees { get; set; } = new List<Employee>();
    public EmployeeCodeSequence? CodeSequence { get; set; }
}

public class Role
{
    [Key]
    public int RoleId { get; set; }

    [Required, MaxLength(100)]
    public string RoleName { get; set; } = string.Empty;

    public int? DepartmentId { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    [ForeignKey(nameof(DepartmentId))]
    public Department? Department { get; set; }
    public ICollection<Employee> Employees { get; set; } = new List<Employee>();
}

public class EmployeeCodeSequence
{
    [Key]
    public int SequenceId { get; set; }
    public int DepartmentId { get; set; }
    public int LastSequence { get; set; } = 0;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(DepartmentId))]
    public Department? Department { get; set; }
}

public class Employee
{
    [Key]
    public int EmployeeId { get; set; }

    [Required, MaxLength(10)]
    public string EmployeeCode { get; set; } = string.Empty;

    [Required, MaxLength(150)]
    public string FullName { get; set; } = string.Empty;

    [Required, MaxLength(200)]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(10)]
    public string MobileNumber { get; set; } = string.Empty;

    [Required, MaxLength(10)]
    public string Gender { get; set; } = string.Empty;

    [Required]
    public DateOnly DateOfBirth { get; set; }

    [Required, MaxLength(500)]
    public string Address { get; set; } = string.Empty;

    public int DepartmentId { get; set; }
    public int RoleId { get; set; }

    [Required]
    public DateOnly JoiningDate { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal AnnualSalary { get; set; }

    [MaxLength(20)]
    public string EmployeeStatus { get; set; } = "Active";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    [ForeignKey(nameof(DepartmentId))]
    public Department? Department { get; set; }

    [ForeignKey(nameof(RoleId))]
    public Role? Role { get; set; }

    public EmployeePersonalDetail? PersonalDetail { get; set; }
    public ICollection<EmployeeTransferHistory> TransferHistories { get; set; } = new List<EmployeeTransferHistory>();
}

public class EmployeePersonalDetail
{
    [Key]
    public int PersonalDetailId { get; set; }
    public int EmployeeId { get; set; }

    [Required, MaxLength(500)]
    public string AadhaarEncrypted { get; set; } = string.Empty;

    [Required, MaxLength(64)]
    public string AadhaarHash { get; set; } = string.Empty;

    [Required, MaxLength(500)]
    public string PANEncrypted { get; set; } = string.Empty;

    [Required, MaxLength(64)]
    public string PANHash { get; set; } = string.Empty;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(EmployeeId))]
    public Employee? Employee { get; set; }
}

public class EmployeeTransferHistory
{
    [Key]
    public int TransferId { get; set; }
    public int EmployeeId { get; set; }
    public int OldDepartmentId { get; set; }
    public int NewDepartmentId { get; set; }

    [Required, MaxLength(10)]
    public string OldEmployeeCode { get; set; } = string.Empty;

    [Required, MaxLength(10)]
    public string NewEmployeeCode { get; set; } = string.Empty;

    public int OldRoleId { get; set; }
    public int NewRoleId { get; set; }

    public DateOnly TransferDate { get; set; }

    [Required, MaxLength(1000)]
    public string TransferReason { get; set; } = string.Empty;

    public int? TransferredBy { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    [ForeignKey(nameof(EmployeeId))]
    public Employee? Employee { get; set; }

    [ForeignKey(nameof(OldDepartmentId))]
    public Department? OldDepartment { get; set; }

    [ForeignKey(nameof(NewDepartmentId))]
    public Department? NewDepartment { get; set; }

    [ForeignKey(nameof(OldRoleId))]
    public Role? OldRole { get; set; }

    [ForeignKey(nameof(NewRoleId))]
    public Role? NewRole { get; set; }
}

public class User
{
    [Key]
    public int UserId { get; set; }

    [Required, MaxLength(200)]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(300)]
    public string PasswordHash { get; set; } = string.Empty;

    [MaxLength(20)]
    public string UserRole { get; set; } = "Employee";

    public int? EmployeeId { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? LastLoginAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(EmployeeId))]
    public Employee? Employee { get; set; }
}
