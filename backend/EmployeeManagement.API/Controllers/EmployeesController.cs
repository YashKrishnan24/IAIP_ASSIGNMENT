using EmployeeManagement.API.Models.DTOs;
using EmployeeManagement.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace EmployeeManagement.API.Controllers;

[ApiController]
[Route("api/employees")]
[Produces("application/json")]
public class EmployeesController : ControllerBase
{
    private readonly IEmployeeService _svc;
    public EmployeesController(IEmployeeService svc) => _svc = svc;

    /// <summary>Get all employees with optional search, filters, sorting and pagination.</summary>
    [HttpGet]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<EmployeeListDto>>), 200)]
    public async Task<IActionResult> GetEmployees([FromQuery] EmployeeFilterRequest filter)
    {
        var result = await _svc.GetEmployeesAsync(filter);
        return Ok(ApiResponse<PagedResult<EmployeeListDto>>.Ok(result));
    }

    /// <summary>Get complete employee details by ID (includes Aadhaar / PAN for Admin and Manager).</summary>
    [HttpGet("{id:int}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<EmployeeDetailDto>), 200)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetEmployee(int id)
    {
        var emp = await _svc.GetEmployeeByIdAsync(id);
        if (emp is null) return NotFound(ApiResponse<object>.Fail("Employee not found."));

        // Mask PII for non-privileged roles
        var role = User.FindFirstValue(ClaimTypes.Role);
        if (role == "Employee")
        {
            emp.AadhaarNumber = "****-****-" + (emp.AadhaarNumber.Length >= 4
                ? emp.AadhaarNumber[^4..] : "****");
            emp.PANNumber = emp.PANNumber.Length >= 4
                ? new string('*', 6) + emp.PANNumber[^4..] : "**********";
        }

        return Ok(ApiResponse<EmployeeDetailDto>.Ok(emp));
    }

    /// <summary>Get employee personal details by ID.</summary>
    [HttpGet("{id:int}/personal-details")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<EmployeeDetailDto>), 200)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> GetPersonalDetails(int id) => await GetEmployee(id);

    /// <summary>Create a new employee.</summary>
    [HttpPost]
    [Authorize(Roles = "Admin,Manager")]
    [ProducesResponseType(typeof(ApiResponse<EmployeeDetailDto>), 201)]
    [ProducesResponseType(400)]
    [ProducesResponseType(409)]
    public async Task<IActionResult> CreateEmployee([FromBody] CreateEmployeeRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ApiResponse<object>.Fail(
                string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage))));

        try
        {
            var emp = await _svc.CreateEmployeeAsync(request);
            return CreatedAtAction(nameof(GetEmployee), new { id = emp.EmployeeId },
                ApiResponse<EmployeeDetailDto>.Ok(emp, "Employee created successfully."));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Update an existing employee.</summary>
    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin,Manager")]
    [ProducesResponseType(typeof(ApiResponse<EmployeeDetailDto>), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> UpdateEmployee(int id, [FromBody] UpdateEmployeeRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ApiResponse<object>.Fail(
                string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage))));

        try
        {
            var emp = await _svc.UpdateEmployeeAsync(id, request);
            return Ok(ApiResponse<EmployeeDetailDto>.Ok(emp, "Employee updated successfully."));
        }
        catch (KeyNotFoundException ex) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
        catch (ArgumentException ex) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
        catch (InvalidOperationException ex) { return Conflict(ApiResponse<object>.Fail(ex.Message)); }
    }

    /// <summary>Deactivate (soft-delete) an employee.</summary>
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(200)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> DeactivateEmployee(int id)
    {
        var ok = await _svc.DeactivateEmployeeAsync(id);
        if (!ok) return NotFound(ApiResponse<object>.Fail("Employee not found."));
        return Ok(ApiResponse<object>.Ok(null!, "Employee deactivated successfully."));
    }

    /// <summary>Transfer an employee to a new department.</summary>
    [HttpPost("transfer")]
    [Authorize(Roles = "Admin,Manager")]
    [ProducesResponseType(typeof(ApiResponse<object>), 200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> TransferEmployee([FromBody] TransferEmployeeRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ApiResponse<object>.Fail(
                string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage))));

        try
        {
            var userId = int.TryParse(User.FindFirstValue("userId"), out var uid) ? (int?)uid : null;
            var newCode = await _svc.TransferEmployeeAsync(request, userId);
            return Ok(ApiResponse<object>.Ok(new { newEmployeeCode = newCode },
                $"Employee transferred successfully. New code: {newCode}"));
        }
        catch (KeyNotFoundException ex)   { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
        catch (ArgumentException ex)      { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
        catch (InvalidOperationException ex) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    /// <summary>Get transfer history for an employee.</summary>
    [HttpGet("{id:int}/transfer-history")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<TransferHistoryDto>>), 200)]
    public async Task<IActionResult> GetTransferHistory(int id)
    {
        var history = await _svc.GetTransferHistoryAsync(id);
        return Ok(ApiResponse<IEnumerable<TransferHistoryDto>>.Ok(history));
    }
}
