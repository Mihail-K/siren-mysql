
module siren.mysql.database.query_row;

import siren.database;

import mysql;

import std.typecons;
import std.variant;

class MySQLQueryRow : QueryRow
{
private:
    const size_t[string] _indexes;
    Row _row;

public:
    this(const size_t[string] indexes, Row row)
    {
        _indexes = indexes;
        _row = row;
    }

    @property
    override string[] columns()
    {
        return _indexes.keys;
    }

    @property
    override Variant get(size_t index)
    {
        return _row[cast(uint) index];
    }

    @property
    override bool isNull(size_t index)
    {
        return _row.isNull(cast(uint) index);
    }

    @property
    override Nullable!Variant opIndex(size_t index)
    {
        Nullable!Variant value;

        if(!isNull(index))
        {
            value = get(index);
        }

        return value;
    }

    @property
    override Nullable!Variant[] toArray()
    {
        auto values = new Nullable!Variant[columns.length];

        foreach(index; 0 .. _indexes.length)
        {
            values[index] = this[index];
        }

        return values;
    }

    @property
    override Nullable!Variant[string] toAssocArray()
    {
        Nullable!Variant[string] values;

        foreach(name, index; _indexes)
        {
            values[name] = this[index];
        }

        return values;
    }
}
