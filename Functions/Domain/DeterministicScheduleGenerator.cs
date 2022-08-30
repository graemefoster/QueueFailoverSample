using System;
using System.Linq;
using QueueFailoverTest.Domain;

namespace SetupDatabase;

public class DeterministicScheduleGenerator
{
    public Schedule[] Generate()
    {
        var from = new DateOnly(2022, 1, 1);
        var seed = new Random(12312);
        return Enumerable.Range(0, 50000)
            .Select(x => new Schedule()
            {
                From = from.AddDays(seed.Next(200)),
                RunForInDays = seed.Next(200),
                Id = new Guid(Enumerable.Range(0, 16).Select(_ => Convert.ToByte(seed.Next(0, 255))).ToArray()),
                Transfer = (DayOfWeek)seed.Next(0, 7),
                AmountInCents = seed.Next(100, 1000)
            }).ToArray();
    }
}