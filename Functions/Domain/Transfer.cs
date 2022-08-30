using System;

namespace QueueFailoverTest.Domain;

public class Transfer
{
    public Guid Id { get; set; }
    public string Date { get; set; }
    public decimal AmountInCents { get; set; }
}