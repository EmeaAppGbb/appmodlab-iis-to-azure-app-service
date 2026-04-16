using System.Text.RegularExpressions;

namespace CascadeHRPortal.Web.Middleware;

/// <summary>
/// Replaces IIS URL Rewrite rules with ASP.NET Core middleware equivalents.
/// Migrated from IIS-Config/urlrewrite.config (17 inbound rules + HSTS outbound rule).
/// </summary>
public class UrlRewriteMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<UrlRewriteMiddleware> _logger;

    private static readonly Regex StaticFileExtensions =
        new(@"\.(css|js|jpg|jpeg|png|gif|ico|woff|woff2|ttf|svg)$", RegexOptions.IgnoreCase | RegexOptions.Compiled);

    public UrlRewriteMiddleware(RequestDelegate next, ILogger<UrlRewriteMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var request = context.Request;
        var path = request.Path.Value ?? string.Empty;
        var host = request.Host.Value ?? string.Empty;

        // --- Rule 1: HTTPS Redirect (stopProcessing) ---
        if (!request.IsHttps)
        {
            var redirectUrl = $"https://{host}{path}{request.QueryString}";
            _logger.LogInformation("HTTPS Redirect: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 6: Remove WWW Prefix (stopProcessing) ---
        if (host.StartsWith("www.", StringComparison.OrdinalIgnoreCase))
        {
            var newHost = host[4..];
            var redirectUrl = $"https://{newHost}{path}{request.QueryString}";
            _logger.LogInformation("Remove WWW: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 2: Legacy HR Portal Redirect (stopProcessing) ---
        var hrPortalMatch = Regex.Match(path, @"^/hr-portal/(.*)$", RegexOptions.IgnoreCase);
        if (hrPortalMatch.Success)
        {
            var redirectUrl = $"/{hrPortalMatch.Groups[1].Value}{request.QueryString}";
            _logger.LogInformation("Legacy HR Portal Redirect: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 3: API v1 to v2 Rewrite (does NOT stop processing) ---
        var apiV1Match = Regex.Match(path, @"^/api/v1/(.*)$", RegexOptions.IgnoreCase);
        if (apiV1Match.Success)
        {
            var newPath = $"/api/v2/{apiV1Match.Groups[1].Value}";
            _logger.LogInformation("API v1→v2 Rewrite: {OldPath} → {NewPath}", path, newPath);
            request.Path = newPath;
            // stopProcessing="false" — continue evaluating subsequent rules
        }

        // --- Rule 4: Remove Trailing Slash (stopProcessing) ---
        if (path.Length > 1 && path.EndsWith('/'))
        {
            var trimmed = path.TrimEnd('/');
            var redirectUrl = $"{trimmed}{request.QueryString}";
            _logger.LogInformation("Remove Trailing Slash: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 5: Lowercase URLs (stopProcessing) ---
        // Only redirect if the path contains uppercase letters and is not a static file
        if (path.Any(char.IsUpper) && !StaticFileExtensions.IsMatch(path))
        {
            var lowerUrl = $"{path.ToLowerInvariant()}{request.QueryString}";
            _logger.LogInformation("Lowercase URL: {Url}", lowerUrl);
            context.Response.Redirect(lowerUrl, permanent: true);
            return;
        }

        // --- Rule 7: Employee Lookup Legacy (stopProcessing) ---
        if (path.Equals("/employees/search", StringComparison.OrdinalIgnoreCase))
        {
            var q = request.Query["q"].FirstOrDefault() ?? string.Empty;
            var redirectUrl = $"/Directory/Search?query={Uri.EscapeDataString(q)}";
            _logger.LogInformation("Employee Lookup Legacy: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 8: Payslip Download Legacy (stopProcessing) ---
        var payslipMatch = Regex.Match(path, @"^/payslips/download/([0-9]+)$", RegexOptions.IgnoreCase);
        if (payslipMatch.Success)
        {
            var redirectUrl = $"/Payslip/Download/{payslipMatch.Groups[1].Value}";
            _logger.LogInformation("Payslip Download Legacy: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 9: Benefits Legacy URL (stopProcessing) ---
        if (path.Equals("/benefits-enrollment", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation("Benefits Legacy Redirect");
            context.Response.Redirect("/Benefits/Enroll", permanent: true);
            return;
        }

        // --- Rule 10: Leave Status Legacy (stopProcessing) ---
        var leaveMatch = Regex.Match(path, @"^/leave/status/([0-9]+)$", RegexOptions.IgnoreCase);
        if (leaveMatch.Success)
        {
            var redirectUrl = $"/Leave/Details/{leaveMatch.Groups[1].Value}";
            _logger.LogInformation("Leave Status Legacy: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 11: Timesheet Legacy Format (stopProcessing) ---
        var timesheetMatch = Regex.Match(path, @"^/timesheet/submit/([0-9]{4})-W([0-9]{2})$", RegexOptions.IgnoreCase);
        if (timesheetMatch.Success)
        {
            var redirectUrl = $"/Timesheet/Submit?year={timesheetMatch.Groups[1].Value}&week={timesheetMatch.Groups[2].Value}";
            _logger.LogInformation("Timesheet Legacy: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 12: Calendar Legacy URL (stopProcessing) ---
        var calendarMatch = Regex.Match(path, @"^/calendar/([0-9]{4})/([0-9]{2})$", RegexOptions.IgnoreCase);
        if (calendarMatch.Success)
        {
            var redirectUrl = $"/Leave/Calendar?year={calendarMatch.Groups[1].Value}&month={calendarMatch.Groups[2].Value}";
            _logger.LogInformation("Calendar Legacy: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 13: PDF Reports Legacy (stopProcessing) ---
        var reportsMatch = Regex.Match(path, @"^/reports/pdf/([a-z-]+)/([0-9]+)$");
        if (reportsMatch.Success)
        {
            var redirectUrl = $"/Reports/{reportsMatch.Groups[1].Value}?id={reportsMatch.Groups[2].Value}&format=pdf";
            _logger.LogInformation("PDF Reports Legacy: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 14: Mobile Site Redirect (stopProcessing, Temporary) ---
        var mobileMatch = Regex.Match(path, @"^/mobile/(.*)$", RegexOptions.IgnoreCase);
        if (mobileMatch.Success)
        {
            var redirectUrl = $"/{mobileMatch.Groups[1].Value}?mobile=true";
            _logger.LogInformation("Mobile Site Redirect: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: false);
            return;
        }

        // --- Rule 15: Intranet Legacy Path (stopProcessing) ---
        var intranetMatch = Regex.Match(path, @"^/intranet/hr/(.*)$", RegexOptions.IgnoreCase);
        if (intranetMatch.Success)
        {
            var redirectUrl = $"/{intranetMatch.Groups[1].Value}{request.QueryString}";
            _logger.LogInformation("Intranet Legacy: {Url}", redirectUrl);
            context.Response.Redirect(redirectUrl, permanent: true);
            return;
        }

        // --- Rule 16: Payroll API Proxy placeholder (stopProcessing) ---
        // In IIS this rewrote to http://payroll-internal.cascade.local/api/{R:1}
        // with X-Forwarded-Host and X-Forwarded-For headers.
        // TODO: Replace with YARP or HttpClient-based proxy when payroll service endpoint is configured.
        var payrollMatch = Regex.Match(path, @"^/api/payroll/(.*)$", RegexOptions.IgnoreCase);
        if (payrollMatch.Success)
        {
            _logger.LogWarning("Payroll API Proxy: request to {Path} — proxy not yet configured. " +
                "Configure a reverse proxy (e.g. YARP) to forward to the payroll service.", path);
            context.Response.StatusCode = StatusCodes.Status502BadGateway;
            await context.Response.WriteAsync("Payroll API proxy is not yet configured.");
            return;
        }

        // --- Rule 17: Document Service Proxy placeholder (stopProcessing) ---
        // In IIS this rewrote to http://docs-internal.cascade.local/{R:1}
        // only for /documents/(pdf|docx|xlsx)/... paths.
        // TODO: Replace with YARP or HttpClient-based proxy when document service endpoint is configured.
        var docMatch = Regex.Match(path, @"^/documents/(pdf|docx|xlsx)/(.*)$", RegexOptions.IgnoreCase);
        if (docMatch.Success)
        {
            _logger.LogWarning("Document Service Proxy: request to {Path} — proxy not yet configured. " +
                "Configure a reverse proxy (e.g. YARP) to forward to the document service.", path);
            context.Response.StatusCode = StatusCodes.Status502BadGateway;
            await context.Response.WriteAsync("Document service proxy is not yet configured.");
            return;
        }

        // --- Outbound Rule: HSTS Header ---
        // Add Strict-Transport-Security header for HTTPS requests (equivalent to IIS outbound rule).
        if (request.IsHttps)
        {
            context.Response.OnStarting(() =>
            {
                if (!context.Response.Headers.ContainsKey("Strict-Transport-Security"))
                {
                    context.Response.Headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains";
                }
                return Task.CompletedTask;
            });
        }

        await _next(context);
    }
}
