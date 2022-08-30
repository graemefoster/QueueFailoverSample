using System;
using System.Threading.Tasks;
using Dapper;
using Microsoft.Azure.WebJobs;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using QueueFailoverTest.Domain;

namespace QueueFailoverTest;

public static class Consumer
{
    [FunctionName("Consumer")]
    public static async Task Run(
        [QueueTrigger("test-queue", Connection = "StorageAccountSetting")]
        Transfer transfer, ILogger log)
    {
        log.LogInformation("From {Id}. Date {Date}. Amount {Amount}", transfer.Id, transfer.Date,
            transfer.AmountInCents);

        SqlMapper.AddTypeHandler(new DapperSqlDateOnlyTypeHandler());

        //introduce a bit of delay just to slow down consumption a little bit:
        await Task.Delay(TimeSpan.FromSeconds(5));

        using var con = new SqlConnection(Environment.GetEnvironmentVariable("SqlConnectionString"));
        var rows = await con.ExecuteAsync("update Schedule set ProcessedUpto=@Date where Id=@Id", new
        {
            transfer.Id,
            Date = DateOnly.FromDateTime(JsonConvert.DeserializeObject<DateTime>(transfer.Date))
        });
    }
}