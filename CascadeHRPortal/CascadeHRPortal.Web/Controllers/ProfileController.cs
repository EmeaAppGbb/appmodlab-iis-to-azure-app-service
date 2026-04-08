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
            Username = User.Identity?.Name ?? "",
            FirstName = "John", LastName = "Doe",
            Email = "john.doe@cascade.com",
            Department = "Engineering"
        };
        return View(profile);
    }
}
