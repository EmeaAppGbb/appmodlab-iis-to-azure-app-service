using Azure.Storage.Blobs;
using CascadeHRPortal.Services;
using CascadeHRPortal.Web.Middleware;
using Microsoft.Identity.Web;

var builder = WebApplication.CreateBuilder(args);

// Application Insights telemetry
builder.Services.AddApplicationInsightsTelemetry();

// Add services to the container.
builder.Services.AddControllersWithViews();

// Entra ID authentication via Microsoft Identity Web
builder.Services.AddMicrosoftIdentityWebAppAuthentication(builder.Configuration);

// Register Azure Blob Storage client
builder.Services.AddSingleton(_ =>
    new BlobServiceClient(builder.Configuration["AzureStorage:ConnectionString"]));

// Register application services
builder.Services.AddScoped<ILeaveService, LeaveService>();
builder.Services.AddScoped<ITimesheetService, TimesheetService>();
builder.Services.AddScoped<IPayrollIntegrationService, PayrollIntegrationService>();
builder.Services.AddScoped<IDocumentService, DocumentService>();
builder.Services.AddScoped<IEmailService, EmailService>();

// Add session support (legacy pattern)
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

// Custom error pages handled by IIS
app.UseStatusCodePagesWithReExecute("/Error/{0}");

app.UseHttpsRedirection();
app.UseStaticFiles();

// URL rewrite rules migrated from IIS urlrewrite.config
app.UseMiddleware<UrlRewriteMiddleware>();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.UseSession();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
