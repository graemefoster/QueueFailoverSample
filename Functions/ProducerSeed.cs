using System;
using System.Data;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using QueueFailoverTest.Domain;
using SetupDatabase;

namespace QueueFailoverTest;

public static class ProducerSeed
{
    [FunctionName("ProducerSeed")]
    [StorageAccount("StorageAccountSetting")]
    public static async Task<int> Run(
        [HttpTrigger("POST", "GET")] HttpRequest req,
        ILogger log)
    {
        log.LogInformation("ProducerSeed function executing at: {Time}", DateTime.UtcNow);

        SqlMapper.AddTypeHandler(new DapperSqlDateOnlyTypeHandler());
        await using var con = new SqlConnection(Environment.GetEnvironmentVariable("SqlConnectionString"));
        await con.OpenAsync();
        await using var cmd = con.CreateCommand();
        cmd.CommandText = @"
IF EXISTS(SELECT 1 FROM sys.tables WHERE Name='Schedule')
    DROP TABLE Schedule";

        await cmd.ExecuteNonQueryAsync();

        await using var cmd2 = con.CreateCommand();
        cmd2.CommandText = @"
CREATE TABLE Schedule (
        Id uniqueidentifier PRIMARY KEY NOT NULL,
    [From] date NOT NULL,
    RunForInDays int NOT NULL,
    Transfer smallint NOT NULL,
    AmountInCents bigint NOT NULL,
    EnqueuedUpto date NULL,
    ProcessedUpto date NULL
    )";
        await cmd2.ExecuteNonQueryAsync();

        var schedule = new DeterministicScheduleGenerator().Generate();
        var sbi = new SqlBulkCopy(con);
        sbi.DestinationTableName = "Schedule";
        var tbl = new DataTable("Schedule");
        tbl.Columns.Add("Id", typeof(Guid));
        tbl.Columns.Add("From", typeof(DateTime));
        tbl.Columns.Add("RunForInDays", typeof(int));
        tbl.Columns.Add("Transfer", typeof(short));
        tbl.Columns.Add("AmountInCents", typeof(decimal));
        tbl.Columns.Add("EnqueuedUpto", typeof(DateOnly));
        tbl.Columns.Add("ProcessedUpto", typeof(DateOnly));

        foreach (var scheduleItem in schedule)
        {
            tbl.Rows.Add(
                scheduleItem.Id,
                scheduleItem.From.ToDateTime(new TimeOnly()),
                scheduleItem.RunForInDays,
                scheduleItem.Transfer,
                scheduleItem.AmountInCents,
                scheduleItem.EnqueuedUpto,
                scheduleItem.ProcessedUpto);
        }

        await sbi.WriteToServerAsync(tbl);
        log.LogInformation("Seeded {Count} schedules", schedule.Length);
        return schedule.Length;
    }
}