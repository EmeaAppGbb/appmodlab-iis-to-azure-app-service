using CascadeHRPortal.Services.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CascadeHRPortal.Services;

public interface ILeaveService
{
    Task<List<LeaveRequestModel>> GetEmployeeLeaveRequestsAsync(string username);
    Task<ServiceResult> SubmitLeaveRequestAsync(LeaveRequestModel request);
}

public class LeaveService : ILeaveService
{
    private readonly IConfiguration _config;
    private readonly ILogger<LeaveService> _logger;
    private readonly IEmailService _emailService;

    public LeaveService(IConfiguration config, ILogger<LeaveService> logger, IEmailService emailService)
    {
        _config = config;
        _logger = logger;
        _emailService = emailService;
    }

    public Task<List<LeaveRequestModel>> GetEmployeeLeaveRequestsAsync(string username)
    {
        _logger.LogInformation("Fetching leave requests for {Username}", username);
        var requests = new List<LeaveRequestModel> {
            new() { RequestId = 1001, EmployeeUsername = username, LeaveType = "Annual Leave",
                   StartDate = DateTime.Now.AddDays(10), EndDate = DateTime.Now.AddDays(14), 
                   Status = "Pending", SubmittedDate = DateTime.Now.AddDays(-2) }
        };
        return Task.FromResult(requests);
    }

    public async Task<ServiceResult> SubmitLeaveRequestAsync(LeaveRequestModel request)
    {
        _logger.LogInformation("Submitting leave request for {Username}", request.EmployeeUsername);
        try {
            var maxDays = _config.GetValue<int>("AppSettings:MaxLeaveRequestDays", 30);
            if (request.TotalDays > maxDays)
                return ServiceResult.FailureResult($"Cannot exceed {maxDays} days");
            
            request.RequestId = new Random().Next(1000, 9999);
            request.SubmittedDate = DateTime.Now;
            await _emailService.SendLeaveRequestNotificationAsync(request);
            return ServiceResult.SuccessResult();
        } catch (Exception ex) {
            _logger.LogError(ex, "Error submitting leave request");
            return ServiceResult.FailureResult("An error occurred");
        }
    }
}
