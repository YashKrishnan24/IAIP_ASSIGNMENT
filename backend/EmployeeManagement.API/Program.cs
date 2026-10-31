using System.Text;
using EmployeeManagement.API.Data;
using EmployeeManagement.API.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// ─── Database ─────────────────────────────────────────────────────────────────
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"),
        sql => sql.CommandTimeout(60)));

// ─── Application Services & Security Validation ──────────────────────────────
var encKey = builder.Configuration["Encryption:Key"];
if (string.IsNullOrWhiteSpace(encKey))
{
    throw new InvalidOperationException("Configuration error: 'Encryption:Key' is missing or empty. A valid 256-bit AES encryption key must be provided.");
}

builder.Services.AddSingleton<IEncryptionService, EncryptionService>();
builder.Services.AddScoped<IEmployeeService, EmployeeService>();
builder.Services.AddScoped<IAuthService, AuthService>();

// ─── JWT Auth ─────────────────────────────────────────────────────────────────
var jwtSection = builder.Configuration.GetSection("JwtSettings");
var secretKey  = jwtSection["SecretKey"];
if (string.IsNullOrWhiteSpace(secretKey))
{
    throw new InvalidOperationException("Configuration error: 'JwtSettings:SecretKey' is missing or empty. A valid JWT signing key must be provided.");
}

var issuer   = jwtSection["Issuer"] ?? "EmployeeManagementAPI";
var audience = jwtSection["Audience"] ?? "EmployeeManagementClient";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = issuer,
            ValidAudience            = audience,
            IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
            ClockSkew                = TimeSpan.Zero,
        };
    });

builder.Services.AddAuthorization();

// ─── CORS ─────────────────────────────────────────────────────────────────────
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? new[] { "*" };

builder.Services.AddCors(opt =>
    opt.AddPolicy("FrontendPolicy", policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials()));

// ─── Controllers + Swagger ────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title       = "Employee Management API",
        Version     = "v1",
        Description = "REST API for Employee Management System with CRUD, transfers, and RBAC.",
    });

    var jwtScheme = new OpenApiSecurityScheme
    {
        BearerFormat = "JWT",
        Name         = "Authorization",
        In           = ParameterLocation.Header,
        Type         = SecuritySchemeType.Http,
        Scheme       = JwtBearerDefaults.AuthenticationScheme,
        Description  = "Enter your JWT Bearer token.",
        Reference    = new OpenApiReference { Id = "Bearer", Type = ReferenceType.SecurityScheme },
    };
    c.AddSecurityDefinition("Bearer", jwtScheme);
    c.AddSecurityRequirement(new OpenApiSecurityRequirement { { jwtScheme, Array.Empty<string>() } });
});

// ─── Build & Pipeline ─────────────────────────────────────────────────────────
var app = builder.Build();

// 1. Global Error Handler (FIRST in pipeline to catch all downstream errors)
app.UseExceptionHandler(errApp => errApp.Run(async ctx =>
{
    var exceptionFeature = ctx.Features.Get<IExceptionHandlerFeature>();
    var ex = exceptionFeature?.Error;

    var (statusCode, message) = ex switch
    {
        KeyNotFoundException knf => (StatusCodes.Status404NotFound, knf.Message),
        ArgumentException arg   => (StatusCodes.Status400BadRequest, arg.Message),
        InvalidOperationException inv => (StatusCodes.Status400BadRequest, inv.Message),
        DbUpdateException dbEx when dbEx.InnerException?.Message.Contains("UNIQUE") == true
            || dbEx.InnerException?.Message.Contains("duplicate") == true
            => (StatusCodes.Status409Conflict, "A record with this unique identifier (Email, Aadhaar, PAN, or Employee Code) already exists."),
        DbUpdateException => (StatusCodes.Status409Conflict, "Database conflict occurred."),
        _ => (StatusCodes.Status500InternalServerError, "An unexpected server error occurred.")
    };

    ctx.Response.StatusCode  = statusCode;
    ctx.Response.ContentType = "application/json";
    await ctx.Response.WriteAsJsonAsync(new
    {
        success = false,
        message = message,
    });
}));

app.UseCors("FrontendPolicy");

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Employee Management API v1");
        c.RoutePrefix = "swagger";
    });
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
