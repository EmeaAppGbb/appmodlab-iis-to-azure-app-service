using Azure.Storage.Blobs;
using CascadeHRPortal.Services.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CascadeHRPortal.Services;

public interface IDocumentService
{
    Task<PayslipDocument?> GetPayslipDocumentAsync(int payslipId, string username);
    Task<byte[]?> GetDocumentAsync(string containerName, string blobName);
    Task UploadDocumentAsync(string containerName, string blobName, byte[] content, string contentType);
}

public class DocumentService : IDocumentService
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly IConfiguration _config;
    private readonly ILogger<DocumentService> _logger;

    public DocumentService(BlobServiceClient blobServiceClient, IConfiguration config, ILogger<DocumentService> logger)
    {
        _blobServiceClient = blobServiceClient;
        _config = config;
        _logger = logger;
    }

    public async Task<PayslipDocument?> GetPayslipDocumentAsync(int payslipId, string username)
    {
        _logger.LogInformation("Fetching payslip document {PayslipId} for {Username}", payslipId, username);

        var containerName = _config["AzureStorage:ContainerNames:Payslips"] ?? "payslips";
        var blobName = $"{username}/Payslip_{payslipId}.pdf";

        try
        {
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(blobName);

            if (!await blobClient.ExistsAsync())
            {
                _logger.LogWarning("Payslip blob {BlobName} not found in container {Container}", blobName, containerName);
                return null;
            }

            using var memoryStream = new MemoryStream();
            await blobClient.DownloadToAsync(memoryStream);

            return new PayslipDocument
            {
                Content = memoryStream.ToArray(),
                FileName = $"Payslip_{payslipId}.pdf"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching payslip {PayslipId} from blob storage", payslipId);
            return null;
        }
    }

    public async Task<byte[]?> GetDocumentAsync(string containerName, string blobName)
    {
        _logger.LogInformation("Fetching document {BlobName} from container {Container}", blobName, containerName);

        try
        {
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(blobName);

            if (!await blobClient.ExistsAsync())
            {
                _logger.LogWarning("Blob {BlobName} not found in container {Container}", blobName, containerName);
                return null;
            }

            using var memoryStream = new MemoryStream();
            await blobClient.DownloadToAsync(memoryStream);
            return memoryStream.ToArray();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching document {BlobName} from container {Container}", blobName, containerName);
            return null;
        }
    }

    public async Task UploadDocumentAsync(string containerName, string blobName, byte[] content, string contentType)
    {
        _logger.LogInformation("Uploading document {BlobName} to container {Container}", blobName, containerName);

        var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
        await containerClient.CreateIfNotExistsAsync();

        var blobClient = containerClient.GetBlobClient(blobName);
        using var stream = new MemoryStream(content);
        await blobClient.UploadAsync(stream, new Azure.Storage.Blobs.Models.BlobHttpHeaders
        {
            ContentType = contentType
        });
    }
}
