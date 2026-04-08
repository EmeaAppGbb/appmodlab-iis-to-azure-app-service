using CascadeHRPortal.Services.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CascadeHRPortal.Services;

public interface IEmailService
{
    Task SendLeaveRequestNotificationAsync(LeaveRequestModel request);
}

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public Task SendLeaveRequestNotificationAsync(LeaveRequestModel request)
    {
        _logger.LogInformation("Sending leave request notification for {RequestId}", request.RequestId);
        var smtpHost = _config["SmtpSettings:Host"] ?? "smtp-relay.cascade.local";
        _logger.LogInformation("Would send via SMTP: {Host}", smtpHost);
        return Task.CompletedTask;
    }
}
