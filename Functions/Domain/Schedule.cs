using System;
using Newtonsoft.Json;

namespace QueueFailoverTest.Domain;

public class Schedule
{
    public Guid Id { get; set; }
    public DateOnly From { get; set; }
    public int RunForInDays { get; set; }
    public DayOfWeek Transfer { get; set; }
    public long AmountInCents { get; set; }
    public DateOnly? EnqueuedUpto { get; set; }
    public DateOnly? ProcessedUpto { get; set; }

    public bool IsTransferDay(DateOnly now)
    {
        return now >= From && From.AddDays(RunForInDays) <= now && Transfer == now.DayOfWeek;
    }

    public bool NotEnqueued(DateOnly now)
    {
        return EnqueuedUpto == null ||  EnqueuedUpto < now;
    }
    public bool NotProcessed()
    {
        return EnqueuedUpto != null ||  ProcessedUpto == null;
    }

    public Transfer CreateTransfer(DateOnly now)
    {
        return new Transfer()
        {
            Id = Id,
            Date = JsonConvert.SerializeObject(now.ToDateTime(new TimeOnly())),
            AmountInCents = AmountInCents
        };
    }
}