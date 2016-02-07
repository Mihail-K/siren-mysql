
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
