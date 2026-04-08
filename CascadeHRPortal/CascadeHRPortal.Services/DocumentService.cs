using CascadeHRPortal.Services.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CascadeHRPortal.Services;

public interface IDocumentService
{
    Task<PayslipDocument?> GetPayslipDocumentAsync(int payslipId, string username);
}

public class DocumentService : IDocumentService
{
    private readonly IConfiguration _config;
    private readonly ILogger<DocumentService> _logger;

    public DocumentService(IConfiguration config, ILogger<DocumentService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public Task<PayslipDocument?> GetPayslipDocumentAsync(int payslipId, string username)
    {
        _logger.LogInformation("Fetching payslip document {PayslipId} for {Username}", payslipId, username);
        // In real app: Read from IIS virtual directory \\fileserver\payslips
        var basePath = _config["FileStorage:PayslipsPath"] ?? "\\\\fileserver\\payslips";
        _logger.LogInformation("Virtual directory path: {Path}", basePath);
        
        var mockContent = System.Text.Encoding.ASCII.GetBytes("%PDF-1.4\n% Mock Payslip\n%%EOF");
        var doc = new PayslipDocument {
            Content = mockContent,
            FileName = $"Payslip_{payslipId}.pdf"
        };
        return Task.FromResult<PayslipDocument?>(doc);
    }
}
