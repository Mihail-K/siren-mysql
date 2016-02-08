
module siren.mysql.database.escape;

import siren.util;

import std.string;
import std.traits;

@property
EscapedString escapeMySQL(String)(String raw)
if(isSomeString!String)
{
    enum table = [
        '\0'   : "\\0",
        '\''   : "\\'",
        '"'    : "\\\"",
        '\b'   : "\\b",
        '\n'   : "\\n",
        '\r'   : "\\r",
        '\t'   : "\\t",
        '\032' : "\\Z",
        '\\'   : "\\\\"
    ];

    return raw.translate(table).assumeEscaped;
}

@property
string quoteName(String)(String name)
if(isSomeString!String)
{
    if(name.length)
    {
        if(name == "*")
        {
            return name;
        }
        else if(name[0] == '`' && name[$ - 1] == '`')
        {
            return name;
        }
        else
        {
            return '`' ~ name ~ '`';
        }
    }
    else
    {
        return name;
    }
}
