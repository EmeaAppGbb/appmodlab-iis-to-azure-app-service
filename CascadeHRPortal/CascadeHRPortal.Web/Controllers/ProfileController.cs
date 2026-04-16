using System.Security.Claims;
using CascadeHRPortal.Services.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CascadeHRPortal.Web.Controllers;

[Authorize]
public class ProfileController : Controller
{
    public IActionResult Index()
    {
        var profile = new EmployeeProfileModel {
            Username = User.FindFirst("preferred_username")?.Value ?? "",
            FirstName = User.FindFirst(ClaimTypes.GivenName)?.Value ?? "John",
            LastName = User.FindFirst(ClaimTypes.Surname)?.Value ?? "Doe",
            Email = User.FindFirst(ClaimTypes.Email)?.Value ?? "",
            Department = "Engineering"
        };
        return View(profile);
    }
}
