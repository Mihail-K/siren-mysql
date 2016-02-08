
module siren.mysql.database.insert_result;

import siren.database;

import mysql;

import std.typecons;

class MySQLInsertResult : InsertResult
{
private:
    Command _command;
    ulong   _count;

public:
    this(ulong count, Command command)
    {
        _command = command;
        _count   = count;
    }

    @property
    Command command()
    {
        return _command;
    }

    @property
    override ulong count()
    {
        return _count;
    }

    @property
    override Nullable!ulong lastInsertID()
    {
        Nullable!ulong id = _command.lastInsertID;

        return id;
    }
}
