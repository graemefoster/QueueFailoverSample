using System;
using System.Linq;
using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.Azure.WebJobs;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using QueueFailoverTest.Domain;

namespace QueueFailoverTest;

public static class ProducerFailover
{
    [FunctionName("ProducerFailover")]
    [StorageAccount("StorageAccountSetting")]
    public static void Run(
        [HttpTrigger("POST")] HttpRequest myTimer,
        [Queue("test-queue", Connection = "StorageAccountSetting")]
        ICollector<Transfer> outputs,
        ILogger log)
    {
        SqlMapper.AddTypeHandler(new DapperSqlDateOnlyTypeHandler());
        log.LogInformation("Producer function executing at: {Time}", DateTime.UtcNow);

        using var con = new SqlConnection(Environment.GetEnvironmentVariable("SqlConnectionString"));
        var schedule = con.Query<Schedule>("select * from Schedule");
        var today = DateOnly.FromDateTime(DateTime.Now);
        var transferCount = 0;

        var toSchedule = schedule
            .Where(x => x.IsTransferDay(today))
            .Where(x => x.NotProcessed())
            .Select(x => x.CreateTransfer(today));

        foreach (var transfer in toSchedule)
        {
            outputs.Add(transfer);
            transferCount++;
        }

        con.ExecuteAsync("update Schedule set EnqueuedUpto=@Date, ProcessedUpto = null where Id IN @Ids",
            new
            {
                Ids = toSchedule.Select(x => x.Id).ToArray(),
                Date = today
            });


        log.LogInformation("Producer re-queued {Count} transfers", transferCount);
    }
}