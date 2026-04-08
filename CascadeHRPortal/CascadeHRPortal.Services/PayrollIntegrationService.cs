using CascadeHRPortal.Services.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CascadeHRPortal.Services;

public interface IPayrollIntegrationService
{
    Task<List<PayslipModel>> GetEmployeePayslipsAsync(string username);
}

public class PayrollIntegrationService : IPayrollIntegrationService
{
    private readonly IConfiguration _config;
    private readonly ILogger<PayrollIntegrationService> _logger;

    public PayrollIntegrationService(IConfiguration config, ILogger<PayrollIntegrationService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public Task<List<PayslipModel>> GetEmployeePayslipsAsync(string username)
    {
        _logger.LogInformation("Fetching payslips for {Username} from payroll API", username);
        var payslips = new List<PayslipModel> {
            new() { PayslipId = 7001, EmployeeUsername = username, PayPeriodYear = DateTime.Now.Year,
                   PayPeriodMonth = DateTime.Now.Month - 1, PayDate = DateTime.Now.AddDays(-15),
                   GrossPay = 5000m, TaxDeductions = 1200m, BenefitDeductions = 450m }
        };
        return Task.FromResult(payslips);
    }
}
