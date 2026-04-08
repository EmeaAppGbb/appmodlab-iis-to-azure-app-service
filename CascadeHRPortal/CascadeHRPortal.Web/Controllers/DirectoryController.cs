using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CascadeHRPortal.Web.Controllers;

[Authorize]
public class DirectoryController : Controller
{
    public IActionResult Index() => View();
    public IActionResult Search(string? query) => View("SearchResults");
}
