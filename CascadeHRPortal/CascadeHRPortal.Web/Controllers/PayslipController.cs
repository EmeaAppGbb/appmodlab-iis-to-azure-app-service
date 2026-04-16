using CascadeHRPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CascadeHRPortal.Web.Controllers;

[Authorize]
public class PayslipController : Controller
{
    private readonly IPayrollIntegrationService _payrollService;
    private readonly IDocumentService _documentService;
    public PayslipController(IPayrollIntegrationService payrollService, IDocumentService documentService)
    {
        _payrollService = payrollService;
        _documentService = documentService;
    }

    public async Task<IActionResult> Index()
    {
        var username = User.FindFirst("preferred_username")?.Value ?? "";
        var payslips = await _payrollService.GetEmployeePayslipsAsync(username);
        return View(payslips);
    }

    public async Task<IActionResult> Download(int id)
    {
        var doc = await _documentService.GetPayslipDocumentAsync(id, User.FindFirst("preferred_username")?.Value ?? "");
        return doc == null ? NotFound() : File(doc.Content, "application/pdf", doc.FileName);
    }
}
