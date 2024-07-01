table 71033576 "SPBLIC IsoStore Map"
{
    Caption = 'LIC IsoStore Map';
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; IsoKey; Text[1024])
        {
            Caption = 'Key';
        }
        field(2; Value; Text[1024])
        {
            Caption = 'Value';
        }

        field(10; "Origin Entry Id"; guid)
        {
            Caption = 'Origin Entry Id';
        }
    }
    keys
    {
        key(PK; IsoKey)
        {
            Clustered = true;
        }
        key(ByOrigin; "Origin Entry Id")
        { }
    }
}
