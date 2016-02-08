
module siren.mysql.database.savepoint;

struct SavePoint
{
private:
    void delegate(bool)[] _hooks;

    string _name;

public:
    this(string name)
    {
        _name = name;
    }

    void add(void delegate(bool) hook)
    {
        _hooks ~= hook;
    }

    @property
    void delegate(bool)[] hooks()
    {
        return _hooks;
    }

    @property
    string name()
    {
        return _name;
    }
}
