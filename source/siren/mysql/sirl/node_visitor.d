
module siren.mysql.sirl.node_visitor;

import siren.mysql.util.bind;
import siren.mysql.util.escape;

import siren.sirl;

import std.array;
import std.conv;

class MySQLNodeVisitor : NodeVisitor
{
private:
    Appender!string _buffer;

public:
    this()
    {
        _buffer = appender!string;
    }

    @property
    string data()
    {
        return _buffer.data;
    }

    override void visit(AndNode node)
    {
        node.left.accept(this);
        _buffer ~= " AND ";
        node.right.accept(this);
    }

    override void visit(ArithmeticNode node)
    {
        node.left.accept(this);
        _buffer ~= " " ~ node.operator ~ " ";
        node.right.accept(this);
    }

    override void visit(AssignNode node)
    {
        node.left.accept(this);
        _buffer ~= " = ";
        node.right.accept(this);
    }

    override void visit(DeleteNode node)
    {
        _buffer ~= "DELETE FROM ";
        node.table.accept(this);

        if(node.where !is null)
        {
            _buffer ~= " ";
            node.where.accept(this);
        }
    }

    override void visit(EqualityNode node)
    {
        node.left.accept(this);
        _buffer ~= " " ~ node.operator ~ " ";
        node.right.accept(this);
    }

    override void visit(FieldNode node)
    {
        if(node.table.length > 0)
        {
            _buffer ~= node.table.quoteName;
            _buffer ~= ".";
        }

        _buffer ~= node.field.quoteName;
    }

    override void visit(InNode node)
    {
        node.left.accept(this);
        _buffer ~= " " ~ node.operator ~ " ";
        node.right.accept(this);
    }

    override void visit(InsertNode node)
    {
        _buffer ~= "INSERT INTO ";
        node.table.accept(this);

        if(node.fields.length > 0)
        {
            _buffer ~= "(";

            foreach(index, field; node.fields)
            {
                field.accept(this);

                if(index < node.fields.length - 1)
                {
                    _buffer ~= ", ";
                }
            }

            _buffer ~= ")";
        }

        if(node.values !is null)
        {
            _buffer ~= " ";
            node.values.accept(this);
        }
    }

    override void visit(IsNullNode node)
    {
        node.operand.accept(this);
        _buffer ~= " " ~ node.operator;
    }

    override void visit(LimitNode node)
    {
        _buffer ~= "LIMIT ";
        _buffer ~= node.limit.text;
    }

    override void visit(LiteralNode node)
    {
        _buffer ~= node.value.expandParameter;
    }

    override void visit(NotNode node)
    {
        _buffer ~= "NOT ";
        node.operand.accept(this);
    }

    override void visit(OffsetNode node)
    {
        _buffer ~= "OFFSET ";
        _buffer ~= node.offset.text;
    }

    override void visit(OrNode node)
    {
        node.left.accept(this);
        _buffer ~= " OR ";
        node.right.accept(this);
    }

    override void visit(OrderNode node)
    {
        node.field.accept(this);
        _buffer ~= " " ~ node.direction;
    }

    override void visit(RelationNode node)
    {
        node.left.accept(this);
        _buffer ~= " " ~ node.operator ~ " ";
        node.right.accept(this);
    }

    override void visit(SelectNode node)
    {
        _buffer ~= "SELECT ";

        if(node.projection.length > 0)
        {
            foreach(index, field; node.projection)
            {
                field.accept(this);

                if(index < node.projection.length - 1)
                {
                    _buffer ~= ", ";
                }
            }
        }
        else
        {
            FieldNode.create(node.table.table, null).accept(this);
        }

        _buffer ~= " FROM ";
        node.table.accept(this);

        if(node.where !is null)
        {
            _buffer ~= " ";
            node.where.accept(this);
        }

        if(node.orders.length > 0)
        {
            _buffer ~= " ORDER BY ";

            foreach(index, order; node.orders)
            {
                order.accept(this);

                if(index < node.orders.length - 1)
                {
                    _buffer ~= ", ";
                }
            }
        }

        if(node.limit !is null)
        {
            _buffer ~= " ";
            node.limit.accept(this);
        }

        if(node.offset !is null)
        {
            _buffer ~= " ";
            node.offset.accept(this);
        }
    }

    override void visit(SetNode node)
    {
        _buffer ~= "SET ";

        foreach(index, set; node.sets)
        {
            set.accept(this);

            if(index < node.sets.length - 1)
            {
                _buffer ~= ", ";
            }
        }
    }

    override void visit(TableNode node)
    {
        if(node.database.length > 0)
        {
            _buffer ~= node.database.quoteName;
            _buffer ~= ".";
        }

        _buffer ~= node.table.quoteName;
    }

    override void visit(UpdateNode node)
    {
        _buffer ~= "UPDATE ";
        node.table.accept(this);

        if(node.set !is null)
        {
            _buffer ~= " ";
            node.set.accept(this);
        }

        if(node.where !is null)
        {
            _buffer ~= " ";
            node.where.accept(this);
        }
    }

    override void visit(ValuesNode node)
    {
        _buffer ~= "VALUES(";

        foreach(index, value; node.values)
        {
            value.accept(this);

            if(index < node.values.length - 1)
            {
                _buffer ~= ", ";
            }
        }

        _buffer ~= ")";
    }

    override void visit(WhereNode node)
    {
        _buffer ~= "WHERE ";

        foreach(index, clause; node.clauses)
        {
            clause.accept(this);

            if(index < node.clauses.length - 1)
            {
                _buffer ~= " AND ";
            }
        }
    }
}
