using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BCrypt.Net;
using EmployeeManagement.API.Models;
using EmployeeManagement.API.Models.DTOs;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace EmployeeManagement.API.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request);
}

public class AuthService : IAuthService
{
    private readonly Data.AppDbContext _ctx;
    private readonly IConfiguration _config;

    public AuthService(Data.AppDbContext ctx, IConfiguration config)
    {
        _ctx    = ctx;
        _config = config;
    }

    public async Task<LoginResponse?> LoginAsync(LoginRequest request)
    {
        var user = await _ctx.Users
            .FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive);

        if (user is null) return null;

        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return null;

        // Reliably update last login timestamp
        user.LastLoginAt = DateTime.UtcNow;
        await _ctx.SaveChangesAsync();

        var token   = GenerateJwtToken(user);
        var expiry  = DateTime.UtcNow.AddMinutes(
            int.TryParse(_config["JwtSettings:ExpiryInMinutes"], out var m) ? m : 60);

        return new LoginResponse
        {
            Token      = token,
            UserRole   = user.UserRole,
            Email      = user.Email,
            EmployeeId = user.EmployeeId,
            ExpiresAt  = expiry,
        };
    }

    private string GenerateJwtToken(User user)
    {
        var jwtSettings = _config.GetSection("JwtSettings");
        var key         = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtSettings["SecretKey"]!));
        var creds       = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiry      = DateTime.UtcNow.AddMinutes(
            int.TryParse(jwtSettings["ExpiryInMinutes"], out var m) ? m : 60);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub,   user.UserId.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(ClaimTypes.Role,               user.UserRole),
            new Claim("userId",                      user.UserId.ToString()),
            new Claim("employeeId",                  user.EmployeeId?.ToString() ?? ""),
        };

        var token = new JwtSecurityToken(
            issuer:             jwtSettings["Issuer"],
            audience:           jwtSettings["Audience"],
            claims:             claims,
            expires:            expiry,
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
