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
        var timesheets = await _timesheetService.GetEmployeeTimesheetsAsync(User.Identity?.Name ?? "");
        return View(timesheets);
    }

    public IActionResult Submit() => View();
}
