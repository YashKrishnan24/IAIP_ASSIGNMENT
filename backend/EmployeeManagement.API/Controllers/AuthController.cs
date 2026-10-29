using EmployeeManagement.API.Models.DTOs;
using EmployeeManagement.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace EmployeeManagement.API.Controllers;

[ApiController]
[Route("api/auth")]
[Produces("application/json")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authSvc;
    public AuthController(IAuthService authSvc) => _authSvc = authSvc;

    /// <summary>Login and receive a JWT token.</summary>
    [HttpPost("login")]
    [ProducesResponseType(typeof(ApiResponse<LoginResponse>), 200)]
    [ProducesResponseType(401)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ApiResponse<object>.Fail(
                string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage))));

        var result = await _authSvc.LoginAsync(request);
        if (result is null)
            return Unauthorized(ApiResponse<object>.Fail("Invalid email or password."));

        return Ok(ApiResponse<LoginResponse>.Ok(result, "Login successful."));
    }
}
