using System;
using System.Data;
using Dapper;

namespace QueueFailoverTest.Domain;

public class DapperSqlDateOnlyTypeHandler : SqlMapper.TypeHandler<DateOnly?>
{
    public override void SetValue(IDbDataParameter parameter, DateOnly? date)
        => parameter.Value = date?.ToDateTime(new TimeOnly(0, 0));

    public override DateOnly? Parse(object value)
        => value == null ? null : DateOnly.FromDateTime((DateTime)value);
}