enum 95102 "Token Status"
{
    Extensible = true;

    value(0; Unknown)
    {
        Caption = 'Unknown';
    }
    value(1; Valid)
    {
        Caption = 'Valid';
    }
    value(2; Expired)
    {
        Caption = 'Expired';
    }
    value(3; Invalid)
    {
        Caption = 'Invalid';
    }
    value(4; Refreshing)
    {
        Caption = 'Refreshing';
    }
}