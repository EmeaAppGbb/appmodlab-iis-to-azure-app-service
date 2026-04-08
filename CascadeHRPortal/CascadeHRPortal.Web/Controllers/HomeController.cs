using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CascadeHRPortal.Web.Controllers;

[Authorize]
public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    public HomeController(ILogger<HomeController> logger) => _logger = logger;

    public IActionResult Index()
    {
        ViewBag.Username = User.Identity?.Name ?? "Unknown User";
        ViewBag.WelcomeMessage = $"Welcome to Cascade HR Portal, {ViewBag.Username}";
        return View();
    }

    [AllowAnonymous]
    [Route("Error/{statusCode}")]
    public IActionResult Error(int statusCode)
    {
        ViewBag.StatusCode = statusCode;
        ViewBag.ErrorMessage = statusCode switch {
            403 => "Access Forbidden",
            404 => "Page Not Found",
            500 => "Internal Server Error",
            _ => "An error occurred"
        };
        return View("Error");
    }
}
