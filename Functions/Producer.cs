using System;
using System.Linq;
using System.Threading.Tasks;
using Dapper;
using Microsoft.Azure.WebJobs;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using QueueFailoverTest.Domain;

namespace QueueFailoverTest;

public static class Producer
{
    [FunctionName("Producer")]
    [StorageAccount("StorageAccountSetting")]
    public static async Task Run(
        [TimerTrigger("*/20 * * * * *")] TimerInfo myTimer,
        [Queue("test-queue", Connection = "StorageAccountSetting")]
        ICollector<Transfer> outputs,
        ILogger log)
    {
        SqlMapper.AddTypeHandler(new DapperSqlDateOnlyTypeHandler());
        log.LogInformation("Producer function executing at: {Time}", DateTime.UtcNow);

        using var con = new SqlConnection(Environment.GetEnvironmentVariable("SqlConnectionString"));
        var today = DateOnly.FromDateTime(DateTime.Now);
        var schedule = con.Query<Schedule>($"select * from [Schedule] WHERE [Transfer] = {(int)today.DayOfWeek}");
        var transferCount = 0;

        var toSchedule = schedule
            .Where(x => x.IsTransferDay(today))
            .Where(x => x.NotEnqueued(today))
            .Select(x => x.CreateTransfer(today))
            .ToArray();

        var batchSize = 500;
        var batches = toSchedule.Length / batchSize;
        for (var i = 0; i <= batches; i++)
        {
            var batch = toSchedule.Skip(i * batchSize).Take(batchSize).ToArray();
            if (batch.Any())
            {
                await con.ExecuteAsync("update Schedule set EnqueuedUpto=@Date, ProcessedUpto = null where Id IN @Ids",
                    new
                    {
                        Ids = batch.Select(x => x.Id).ToArray(),
                        Date = today
                    });
            }
        }

        foreach (var transfer in toSchedule)
        {
            outputs.Add(transfer);
            transferCount++;
        }

        log.LogInformation("Producer function wrote {Count} transfers", transferCount);
    }
}