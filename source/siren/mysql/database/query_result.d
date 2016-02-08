
module siren.mysql.database.query_result;

import siren.mysql.database.query_row;

import siren.database;

import mysql;

class MySQLQueryResult : QueryResult
{
private:
    ResultSet _result;

public:
    this(ResultSet result)
    {
        _result = result;
    }

    @property
    override string[] columns()
    {
        return _result.colNameIndicies.keys;
    }

    @property
    override bool empty()
    {
        return _result.empty;
    }

    @property
    override MySQLQueryRow front()
    {
        return new MySQLQueryRow(_result.colNameIndicies, _result.front);
    }

    override void popFront()
    {
        _result.popFront;
    }

    @property
    override MySQLQueryResult save()
    {
        return new MySQLQueryResult(_result.save);
    }

    override void reset()
    {
        _result.revert;
    }
}
