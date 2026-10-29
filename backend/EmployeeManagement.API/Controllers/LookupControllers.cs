using EmployeeManagement.API.Data;
using EmployeeManagement.API.Models.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EmployeeManagement.API.Controllers;

[ApiController]
[Route("api/departments")]
[Authorize]
[Produces("application/json")]
public class DepartmentsController : ControllerBase
{
    private readonly AppDbContext _ctx;
    public DepartmentsController(AppDbContext ctx) => _ctx = ctx;

    /// <summary>Get all active departments.</summary>
    [HttpGet]
    public async Task<IActionResult> GetDepartments()
    {
        var depts = await _ctx.Departments
            .Where(d => d.IsActive)
            .Select(d => new DepartmentDto
            {
                DepartmentId   = d.DepartmentId,
                DepartmentName = d.DepartmentName,
                DepartmentCode = d.DepartmentCode,
                Description    = d.Description,
            })
            .ToListAsync();

        return Ok(ApiResponse<IEnumerable<DepartmentDto>>.Ok(depts));
    }
}

[ApiController]
[Route("api/roles")]
[Authorize]
[Produces("application/json")]
public class RolesController : ControllerBase
{
    private readonly AppDbContext _ctx;
    public RolesController(AppDbContext ctx) => _ctx = ctx;

    /// <summary>Get all active roles, optionally filtered by department.</summary>
    [HttpGet]
    public async Task<IActionResult> GetRoles([FromQuery] int? departmentId)
    {
        var query = _ctx.Roles.Where(r => r.IsActive).AsQueryable();
        if (departmentId.HasValue)
            query = query.Where(r => r.DepartmentId == departmentId || r.DepartmentId == null);

        var roles = await query
            .Select(r => new RoleDto
            {
                RoleId       = r.RoleId,
                RoleName     = r.RoleName,
                DepartmentId = r.DepartmentId,
                Description  = r.Description,
            })
            .ToListAsync();

        return Ok(ApiResponse<IEnumerable<RoleDto>>.Ok(roles));
    }
}
