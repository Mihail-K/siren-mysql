
module siren.mysql.database.bind;

import siren.mysql.database.escape;

import siren.util;

import std.regex;
import std.typecons;
import std.variant;

EscapedString bindMySQL(EscapedString sql, Nullable!Variant[] parameters...)
{
    size_t index = 0;
    enum pattern = ctRegex!(r"\:\?");

    return sql.value.replaceAll!((c) {
        Nullable!Variant n = parameters[index++];
        if(n.isNull) return "NULL";

        Variant v = n.get;
        if(v.convertsTo!EscapedString)
        {
            return v.get!EscapedString.value;
        }
        else if(v.convertsTo!string)
        {
            return v.get!string.escapeMySQL.value;
        }
        else if(v.convertsTo!bool)
        {
            return v.get!bool ? "true" : "false";
        }
        else
        {
            return v.coerce!string.escapeMySQL.value;
        }
    })(pattern).assumeEscaped;
}
