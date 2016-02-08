
module siren.mysql.util.bind;

import siren.mysql.util.escape;

import siren.util;

import std.conv;
import std.regex;
import std.typecons;
import std.variant;

EscapedString bindMySQL(EscapedString sql, Nullable!Variant[] parameters...)
{
    size_t index = 0;
    enum pattern = ctRegex!(r"\:\?");

    return sql.value
        .replaceAll!((c) => parameters[index++].expandParameter)(pattern)
        .assumeEscaped;
}

@property
string expandParameter(Nullable!Variant parameter)
{
    if(parameter.isNull)
    {
        return "NULL";
    }
    else
    {
        Variant value = parameter.get;

        if(value.convertsTo!EscapedString)
        {
            return "'" ~ value.get!EscapedString.value ~ "'";
        }
        else if(value.convertsTo!string)
        {
            return "'" ~ value.get!string.escapeMySQL.value ~ "'";
        }
        else if(value.convertsTo!bool)
        {
            return value.get!bool ? "true" : "false";
        }
        else if(value.convertsTo!ulong)
        {
            return value.get!ulong.text;
        }
        else if(value.convertsTo!long)
        {
            return value.get!long.text;
        }
        else if(value.convertsTo!uint)
        {
            return value.get!uint.text;
        }
        else if(value.convertsTo!int)
        {
            return value.get!int.text;
        }
        else if(value.convertsTo!ushort)
        {
            return value.get!ushort.text;
        }
        else if(value.convertsTo!short)
        {
            return value.get!short.text;
        }
        else if(value.convertsTo!ubyte)
        {
            return value.get!ubyte.text;
        }
        else if(value.convertsTo!byte)
        {
            return value.get!byte.text;
        }
        else if(value.convertsTo!float)
        {
            return value.get!float.text;
        }
        else if(value.convertsTo!double)
        {
            return value.get!double.text;
        }
        else
        {
            return "'" ~ value.coerce!string.escapeMySQL.value ~ "'";
        }
    }
}
