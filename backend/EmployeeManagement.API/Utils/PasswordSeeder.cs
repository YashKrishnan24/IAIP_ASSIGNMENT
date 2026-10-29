// ============================================================
//  PasswordSeeder.cs
//  Run once to generate correct BCrypt hashes for Users table.
//  The hashes have already been pre-computed and inserted in 03_SeedData.sql
//  This file is provided for reference / re-seeding purposes.
// ============================================================

namespace EmployeeManagement.API.Utils;

public static class PasswordSeeder
{
    public static void GenerateHashes()
    {
        Console.WriteLine("Generating BCrypt hashes for default users...\n");

        var users = new[]
        {
            ("admin@company.com",    "Admin@123"),
            ("manager@company.com",  "Manager@123"),
            ("employee@company.com", "Employee@123"),
        };

        foreach (var (email, password) in users)
        {
            var hash = BCrypt.Net.BCrypt.HashPassword(password, workFactor: 11);
            Console.WriteLine($"-- {email}");
            Console.WriteLine($"-- Password: {password}");
            Console.WriteLine($"Hash: {hash}");
            Console.WriteLine();
        }

        Console.WriteLine("Done. Copy hashes into 03_SeedData.sql UPDATE statements.");
    }
}
