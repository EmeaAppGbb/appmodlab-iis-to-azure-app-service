namespace CascadeHRPortal.Services.Models;

public class LeaveRequestModel
{
    public int RequestId { get; set; }
    public string EmployeeUsername { get; set; } = string.Empty;
    public string LeaveType { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Status { get; set; } = "Pending";
    public string? Notes { get; set; }
    public DateTime SubmittedDate { get; set; }
    public int TotalDays => (EndDate - StartDate).Days + 1;
}

public class ServiceResult
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public static ServiceResult SuccessResult() => new() { Success = true };
    public static ServiceResult FailureResult(string msg) => new() { Success = false, ErrorMessage = msg };
}
