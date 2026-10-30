using Microsoft.EntityFrameworkCore;
using EmployeeManagement.API.Models;

namespace EmployeeManagement.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Department> Departments => Set<Department>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Employee> Employees => Set<Employee>();
    public DbSet<EmployeePersonalDetail> EmployeePersonalDetails => Set<EmployeePersonalDetail>();
    public DbSet<EmployeeTransferHistory> EmployeeTransferHistories => Set<EmployeeTransferHistory>();
    public DbSet<EmployeeCodeSequence> EmployeeCodeSequences => Set<EmployeeCodeSequence>();
    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Department
        modelBuilder.Entity<Department>(e =>
        {
            e.ToTable("Departments");
            e.HasIndex(d => d.DepartmentName).IsUnique();
            e.HasIndex(d => d.DepartmentCode).IsUnique();
        });

        // Role
        modelBuilder.Entity<Role>(e =>
        {
            e.ToTable("Roles");
            e.HasIndex(r => r.RoleName).IsUnique();
            e.HasOne(r => r.Department)
             .WithMany()
             .HasForeignKey(r => r.DepartmentId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // EmployeeCodeSequence
        modelBuilder.Entity<EmployeeCodeSequence>(e =>
        {
            e.ToTable("EmployeeCodeSequences");
            e.HasIndex(s => s.DepartmentId).IsUnique();
            e.HasOne(s => s.Department)
             .WithOne(d => d.CodeSequence)
             .HasForeignKey<EmployeeCodeSequence>(s => s.DepartmentId);
        });

        // Employee
        modelBuilder.Entity<Employee>(e =>
        {
            e.ToTable("Employees");
            e.HasIndex(emp => emp.EmployeeCode).IsUnique();
            e.HasIndex(emp => emp.Email).IsUnique();
            e.Property(emp => emp.AnnualSalary).HasColumnType("decimal(18,2)");

            e.HasOne(emp => emp.Department)
             .WithMany(d => d.Employees)
             .HasForeignKey(emp => emp.DepartmentId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(emp => emp.Role)
             .WithMany(r => r.Employees)
             .HasForeignKey(emp => emp.RoleId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // EmployeePersonalDetail
        modelBuilder.Entity<EmployeePersonalDetail>(e =>
        {
            e.ToTable("EmployeePersonalDetails");
            e.HasIndex(p => p.AadhaarHash).IsUnique();
            e.HasIndex(p => p.PANHash).IsUnique();
            e.HasOne(p => p.Employee)
             .WithOne(emp => emp.PersonalDetail)
             .HasForeignKey<EmployeePersonalDetail>(p => p.EmployeeId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // EmployeeTransferHistory
        modelBuilder.Entity<EmployeeTransferHistory>(e =>
        {
            e.ToTable("EmployeeTransferHistory");
            e.HasOne(h => h.Employee)
             .WithMany(emp => emp.TransferHistories)
             .HasForeignKey(h => h.EmployeeId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(h => h.OldDepartment)
             .WithMany()
             .HasForeignKey(h => h.OldDepartmentId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(h => h.NewDepartment)
             .WithMany()
             .HasForeignKey(h => h.NewDepartmentId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(h => h.OldRole)
             .WithMany()
             .HasForeignKey(h => h.OldRoleId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(h => h.NewRole)
             .WithMany()
             .HasForeignKey(h => h.NewRoleId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // User
        modelBuilder.Entity<User>(e =>
        {
            e.ToTable("Users");
            e.HasIndex(u => u.Email).IsUnique();
            e.HasOne(u => u.Employee)
             .WithMany()
             .HasForeignKey(u => u.EmployeeId)
             .OnDelete(DeleteBehavior.SetNull);
        });
    }
}
