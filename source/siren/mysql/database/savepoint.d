
module siren.mysql.database.savepoint;

struct SavePoint
{
private:
    string _name;

public:
    this(string name)
    {
        _name = name;
    }

    @property
    string name()
    {
        return _name;
    }
}
