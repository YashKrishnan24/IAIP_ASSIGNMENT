using System.Security.Cryptography;
using System.Text;

namespace EmployeeManagement.API.Services;

public interface IEncryptionService
{
    string Encrypt(string plainText);
    string Decrypt(string cipherText);
    string ComputeHash(string input);
}

public class EncryptionService : IEncryptionService
{
    private readonly byte[] _key;

    public EncryptionService(IConfiguration config)
    {
        var rawKey = config["Encryption:Key"] ?? "EmpManagement$SecureEncryptionKey2024!AES256";
        // Derive exact 256-bit (32-byte) key using SHA256
        _key = SHA256.HashData(Encoding.UTF8.GetBytes(rawKey));
    }

    public string Encrypt(string plainText)
    {
        if (string.IsNullOrEmpty(plainText)) return string.Empty;

        using var aes = Aes.Create();
        aes.Key = _key;
        aes.GenerateIV();

        using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
        var plainBytes = Encoding.UTF8.GetBytes(plainText);
        var cipherBytes = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length);

        // Prepend IV to ciphertext (IV length is 16 bytes)
        var result = new byte[aes.IV.Length + cipherBytes.Length];
        Buffer.BlockCopy(aes.IV, 0, result, 0, aes.IV.Length);
        Buffer.BlockCopy(cipherBytes, 0, result, aes.IV.Length, cipherBytes.Length);

        return Convert.ToBase64String(result);
    }

    public string Decrypt(string cipherText)
    {
        if (string.IsNullOrEmpty(cipherText)) return string.Empty;

        try
        {
            var fullCipher = Convert.FromBase64String(cipherText);
            if (fullCipher.Length < 16) return cipherText; // Fallback if plain

            using var aes = Aes.Create();
            aes.Key = _key;

            var iv = new byte[16];
            var cipherBytes = new byte[fullCipher.Length - 16];
            Buffer.BlockCopy(fullCipher, 0, iv, 0, 16);
            Buffer.BlockCopy(fullCipher, 16, cipherBytes, 0, cipherBytes.Length);

            aes.IV = iv;
            using var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);
            var decryptedBytes = decryptor.TransformFinalBlock(cipherBytes, 0, cipherBytes.Length);

            return Encoding.UTF8.GetString(decryptedBytes);
        }
        catch
        {
            // If decryption fails (e.g. legacy plain text), return as-is
            return cipherText;
        }
    }

    public string ComputeHash(string input)
    {
        if (string.IsNullOrEmpty(input)) return string.Empty;
        var normalized = input.Trim().ToUpperInvariant();
        using var hmac = new HMACSHA256(_key);
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(normalized));
        return Convert.ToHexString(hash);
    }
}

