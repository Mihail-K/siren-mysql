
module siren.mysql.database.adapter;

import siren.mysql.database.insert_result;
import siren.mysql.database.query_result;
import siren.mysql.database.savepoint;
import siren.mysql.sirl.node_visitor;
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
            _connection = null;

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

            foreach(hook; savepoint.hooks)
            {
                hook(true);
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

    protected Command construct(EscapedString query)
    {
        return Command(_connection, query.value);
    }

    // Local destroy shadows.
    alias destroy = Adapter.destroy;

    override ulong destroy(EscapedString query, string context)
    {
        return exec(query, context);
    }

    override ulong destroy(DeleteBuilder sirl, string context = null)
    {
        auto visitor = new MySQLNodeVisitor;
        visitor.visit(sirl.node);

        return destroy(visitor.data.assumeEscaped, context);
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
        auto command = construct(query);

        if(command.execSQL(affected))
        {
            command.purgeResult;
        }

        return affected;
    }

    override void hook(void delegate(bool) hook)
    {
        if(inTransaction)
        {
            _savepoints.front.add(hook);
        }
        else
        {
            assert(0); // TODO
        }
    }

    @property
    override bool inTransaction()
    {
        return !_savepoints.empty;
    }

    // Local insert shadows.
    alias insert = Adapter.insert;

    override InsertResult insert(EscapedString query, string context)
    {
        ulong affected = 0;
        auto command = construct(query);

        if(command.execSQL(affected))
        {
            command.purgeResult;
        }

        return new MySQLInsertResult(affected, command);
    }

    override InsertResult insert(InsertBuilder sirl, string context = null)
    {
        auto visitor = new MySQLNodeVisitor;
        visitor.visit(sirl.node);

        return insert(visitor.data.assumeEscaped, context);
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

            foreach(hook; savepoint.hooks)
            {
                hook(false);
            }
        }
        else
        {
            assert(0); // TODO
        }
    }

    // Local select shadows.
    alias select = Adapter.select;

    override QueryResult select(EscapedString query, string context)
    {
        return new MySQLQueryResult(construct(query).execSQLResult);
    }

    override QueryResult select(SelectBuilder sirl, string context = null)
    {
        auto visitor = new MySQLNodeVisitor;
        visitor.visit(sirl.node);

        return select(visitor.data.assumeEscaped, context);
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

    // Local update shadows.
    alias update = Adapter.update;

    override ulong update(EscapedString query, string context)
    {
        return exec(query, context);
    }

    override ulong update(UpdateBuilder sirl, string context = null)
    {
        auto visitor = new MySQLNodeVisitor;
        visitor.visit(sirl.node);

        return update(visitor.data.assumeEscaped, context);
    }
}

/+ - Adapter Registration - +/

private
{
    shared static AdapterProvider.Token _token = null;

    shared static this()
    {
        _token = AdapterProvider.register!(MySQLAdapter)("siren::mysql");
    }

    shared static ~this()
    {
        if(_token !is null)
        {
            scope(exit) _token = null;
            AdapterProvider.unregister(_token);
        }
    }
}
