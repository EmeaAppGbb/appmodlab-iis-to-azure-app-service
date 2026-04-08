using CascadeHRPortal.Services;
using CascadeHRPortal.Services.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CascadeHRPortal.Web.Controllers;

[Authorize]
public class LeaveController : Controller
{
    private readonly ILeaveService _leaveService;
    public LeaveController(ILeaveService leaveService) => _leaveService = leaveService;

    public async Task<IActionResult> Index()
    {
        var requests = await _leaveService.GetEmployeeLeaveRequestsAsync(User.Identity?.Name ?? "");
        return View(requests);
    }

    public IActionResult Request() => View();

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Request(LeaveRequestModel model)
    {
        if (!ModelState.IsValid) return View(model);
        model.EmployeeUsername = User.Identity?.Name ?? "";
        var result = await _leaveService.SubmitLeaveRequestAsync(model);
        if (result.Success) {
            TempData["SuccessMessage"] = "Leave request submitted";
            return RedirectToAction(nameof(Index));
        }
        ModelState.AddModelError("", result.ErrorMessage ?? "Failed");
        return View(model);
    }
}
