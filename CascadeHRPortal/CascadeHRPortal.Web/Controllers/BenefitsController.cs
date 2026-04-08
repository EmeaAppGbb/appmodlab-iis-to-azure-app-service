using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CascadeHRPortal.Web.Controllers;

[Authorize]
public class BenefitsController : Controller
{
    public IActionResult Index() => View();
    public IActionResult Enroll() => View();
}
