namespace CascadeHRPortal.Services.Models;

public class TimesheetModel
{
    public int TimesheetId { get; set; }
    public string EmployeeUsername { get; set; } = string.Empty;
    public DateTime WeekStartDate { get; set; }
    public List<TimesheetEntry> Entries { get; set; } = new();
    public string Status { get; set; } = "Draft";
    public decimal TotalHours => Entries.Sum(e => e.Hours);
}

public class TimesheetEntry
{
    public int EntryId { get; set; }
    public DateTime Date { get; set; }
    public decimal Hours { get; set; }
    public string ProjectCode { get; set; } = string.Empty;
}
