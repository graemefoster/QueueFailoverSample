using System;
using System.Linq;
using System.Threading.Tasks;
using Azure.Storage.Queues;
using Dapper;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.WebJobs;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using QueueFailoverTest.Domain;

namespace QueueFailoverTest;

public class QueueLengthChecker
{
    private readonly TelemetryClient _telemetryClient;

    /// Using dependency injection will guarantee that you use the same configuration for telemetry collected automatically and manually.
    public QueueLengthChecker(TelemetryConfiguration telemetryConfiguration)
    {
        _telemetryClient = new TelemetryClient(telemetryConfiguration);
    }


    [FunctionName("QueueLengthChecker")]
    public async Task Run(
        [TimerTrigger("*/10 * * * * *")] TimerInfo myTimer,
        [Queue("test-queue", Connection = "StorageAccountSetting")]
        QueueClient client,
        ILogger log)
    {
        log.LogInformation("Queue Length function executing at: {Time}", DateTime.UtcNow);
        var messageCount = (await client.GetPropertiesAsync()).Value.ApproximateMessagesCount;
        _telemetryClient.GetMetric("Queue.Primary").TrackValue(messageCount);

        try
        {
            var client2 = new QueueClient(Environment.GetEnvironmentVariable("StorageAccountSettingReplica"),
                "test-queue");
            var messageCount2 = (await client2.GetPropertiesAsync()).Value.ApproximateMessagesCount;
            _telemetryClient.GetMetric("Queue.Replica").TrackValue(messageCount2);
        }
        catch
        {
            //  ignored - fail-over has occured so we will be single region.
        }
    }
}