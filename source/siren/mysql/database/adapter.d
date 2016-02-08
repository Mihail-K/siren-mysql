
module siren.mysql.database.adapter;

import siren.mysql.database.savepoint;
import siren.mysql.util.bind;
import siren.mysql.util.escape;

import siren.config;
import siren.database;
import siren.sirl;
import siren.util;

import mysql;

import std.container.slist;
import std.conv;
import std.exception;
import std.typecons;
import std.variant;

class MySQLAdapter : Adapter
{
private:
    Connection _connection;

    size_t _savecount;
    SList!SavePoint _savepoints;

public:
    override EscapedString bind(EscapedString sql, Nullable!Variant[] parameters...)
    {
        return sql.bindMySQL(parameters);
    }

    override void close()
    {
        if(connected)
        {
            _connection.close;
            _savepoints.clear;
            _savecount = 0;
        }
    }

    override void commit()
    {
        if(inTransaction)
        {
            auto savepoint = _savepoints.front;
            _savepoints.removeFront;

            if(savepoint.name is null)
            {
                auto query = "COMMIT;";
                exec(query.assumeEscaped);
            }
            else
            {
                auto query = "RELEASE SAVEPOINT " ~ savepoint.name ~ ";";
                exec(query.assumeEscaped);
            }
        }
        else
        {
            assert(0); // TODO
        }
    }

    override void connect()
    {
        if(!connected)
        {
            string host     = Config["mysql::host"];
            string username = Config["mysql::username"];
            string password = Config["mysql::password"];
            string database = Config["mysql::db"];

            enforce(host,     "Missing config property mysql::host");
            enforce(username, "Missing config property mysql::username");
            enforce(password, "Missing config property mysql::password");
            enforce(database, "Missing config property mysql::db");

            _connection = new Connection(host, username, password, database);
        }
    }

    @property
    override bool connected()
    {
        return _connection !is null;
    }

    @property
    override Connection connection()
    {
        return _connection;
    }

    // Local destroy shadows.
    alias destroy = Adapter.destroy;

    override ulong destroy(EscapedString query, string context)
    {
        return exec(query, context);
    }

    override void disconnect()
    {
        close;
    }

    override EscapedString escape(string raw)
    {
        return raw.escapeMySQL;
    }

    // Local exec shadows.
    alias exec = Adapter.exec;

    override ulong exec(EscapedString query, string context)
    {
        ulong affected = 0;
        auto command = Command(_connection, query.value);

        if(command.execSQL(affected))
        {
            command.purgeResult;
        }

        return affected;
    }

    @property
    override bool inTransaction()
    {
        return !_savepoints.empty;
    }

    @property
    override string name()
    {
        return "siren::mysql";
    }

    override void reconnect()
    {
        disconnect;
        connect;
    }

    override void rollback()
    {
        if(inTransaction)
        {
            auto savepoint = _savepoints.front;
            _savepoints.removeFront;

            if(savepoint.name is null)
            {
                auto query = "ROLLBACK;";
                exec(query.assumeEscaped);
            }
            else
            {
                auto query = "ROLLBACK TO " ~ savepoint.name ~ ";";
                exec(query.assumeEscaped);
            }
        }
        else
        {
            assert(0); // TODO
        }
    }

    override void transaction()
    {
        if(inTransaction)
        {
            auto savepoint = SavePoint("sp" ~ text(_savecount++));
            _savepoints.insert(savepoint);

            auto query = "SAVEPOINT " ~ savepoint.name ~ ";";
            exec(query.assumeEscaped);
        }
        else
        {
            _savepoints.insert(SavePoint(null));

            auto query = "START TRANSACTION;".assumeEscaped;
            exec(query.assumeEscaped);
        }
    }
}
