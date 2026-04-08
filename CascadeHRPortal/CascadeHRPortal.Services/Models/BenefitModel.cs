namespace CascadeHRPortal.Services.Models;

public class BenefitModel
{
    public int BenefitId { get; set; }
    public string PlanType { get; set; } = string.Empty;
    public string CoverageLevel { get; set; } = string.Empty;
    public DateTime EffectiveDate { get; set; }
    public decimal MonthlyPremium { get; set; }
}
