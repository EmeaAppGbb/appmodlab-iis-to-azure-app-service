namespace CascadeHRPortal.Services.Models;

public class PayslipModel
{
    public int PayslipId { get; set; }
    public string EmployeeUsername { get; set; } = string.Empty;
    public int PayPeriodYear { get; set; }
    public int PayPeriodMonth { get; set; }
    public DateTime PayDate { get; set; }
    public decimal GrossPay { get; set; }
    public decimal TaxDeductions { get; set; }
    public decimal BenefitDeductions { get; set; }
    public decimal NetPay => GrossPay - TaxDeductions - BenefitDeductions;
}

public class PayslipDocument
{
    public byte[] Content { get; set; } = Array.Empty<byte>();
    public string FileName { get; set; } = string.Empty;
}
