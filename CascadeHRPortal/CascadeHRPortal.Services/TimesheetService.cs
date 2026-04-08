using CascadeHRPortal.Services.Models;
using Microsoft.Extensions.Logging;

namespace CascadeHRPortal.Services;

public interface ITimesheetService
{
    Task<List<TimesheetModel>> GetEmployeeTimesheetsAsync(string username);
}

public class TimesheetService : ITimesheetService
{
    private readonly ILogger<TimesheetService> _logger;
    public TimesheetService(ILogger<TimesheetService> logger) => _logger = logger;

    public Task<List<TimesheetModel>> GetEmployeeTimesheetsAsync(string username)
    {
        _logger.LogInformation("Fetching timesheets for {Username}", username);
        var timesheets = new List<TimesheetModel> {
            new() { TimesheetId = 5001, EmployeeUsername = username, 
                   WeekStartDate = DateTime.Now, Status = "Draft" }
        };
        return Task.FromResult(timesheets);
    }
}
