using CascadeHRPortal.Services;
using CascadeHRPortal.Services.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CascadeHRPortal.Web.Controllers;

[Authorize]
public class TimesheetController : Controller
{
    private readonly ITimesheetService _timesheetService;
    public TimesheetController(ITimesheetService timesheetService) => _timesheetService = timesheetService;

    public async Task<IActionResult> Index()
    {
        var username = User.FindFirst("preferred_username")?.Value ?? "";
        var timesheets = await _timesheetService.GetEmployeeTimesheetsAsync(username);
        return View(timesheets);
    }

    public IActionResult Submit() => View();
}
