table 71033 "SPBPL Extension License"
{
    Caption = 'Extension License';
    DataClassification = AccountData;
    DataPerCompany = false;
    DrillDownPageId = "SPBPL Extension Licenses";
    LookupPageId = "SPBPL Extension Licenses";

    fields
    {
        field(1; "Entry Id"; Guid)
        {
            Caption = 'Entry Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; "Extension Name"; Text[100])
        {
            Caption = 'Extension Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; "Product Code"; Text[100])
        {
            Caption = 'Product Code';
            DataClassification = AccountData;
            Editable = false;
        }
        field(4; Activated; Boolean)
        {
            Caption = 'Activated';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnValidate()
            begin
                if Activated then begin
                    "Activated At" := CurrentDateTime();
                    "Activated By" := UserSecurityId();
                    "Trial Grace End Date" := 0D;
                end;
            end;
        }
        field(5; "Installed At"; DateTime)
        {
            Caption = 'Installed At';
            DataClassification = AccountData;
            Editable = false;
        }
        field(6; "Activated At"; DateTime)
        {
            Caption = 'Activated At';
            DataClassification = AccountData;
            Editable = false;
        }
        field(7; "License Key"; Text[50])
        {
            Caption = 'License Key';
            DataClassification = CustomerContent;
            Editable = false;
            ExtendedDatatype = Masked;
        }
        field(8; "Activated By"; Guid)
        {
            Caption = 'Activated By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(9; "Subscription End Date"; DateTime)
        {
            Caption = 'Subscription End Date';
            DataClassification = AccountData;
            Editable = false;
        }
        field(10; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = AccountData;
            Editable = false;
        }
        field(11; "Subscription Ended At"; DateTime)
        {
            Caption = 'Subscription Ended At';
            DataClassification = AccountData;
            Editable = false;
        }
        field(12; "Subscription Cancelled At"; DateTime)
        {
            Caption = 'Subscription Cancelled At';
            DataClassification = AccountData;
            Editable = false;
        }
        field(13; "Subscription Failed At"; DateTime)
        {
            Caption = 'Subscription Failed At';
            DataClassification = AccountData;

        }
        field(14; "Trial Grace End Date"; Date)
        {
            Caption = 'Trial Grace End Date';
            DataClassification = AccountData;
            Editable = false;
        }
        field(20; "Subscription Email"; Text[250])
        {
            Caption = 'Subscription Email';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
        }
        field(21; "Product URL"; Text[250])
        {
            Caption = 'Product URL';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(22; "Support URL"; Text[250])
        {
            Caption = 'Support URL';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(23; "Billing Support Email"; Text[250])
        {
            Caption = 'Billing Support Email';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ExtendedDatatype = EMail;
        }
        field(25; "Version Check URL"; Text[250])
        {
            Caption = 'Version Check URL';
            DataClassification = SystemMetadata;
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(26; "Update Available"; Boolean)
        {
            Caption = 'Update Available';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(27; "Update News URL"; Text[250])
        {
            Caption = 'Update News URL';
            DataClassification = SystemMetadata;
            Editable = false;
            ExtendedDatatype = URL;
        }
        field(30; "License Platform"; Enum "SPBPL License Platform")
        {
            Caption = 'License Platform';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Entry Id")
        {
            Clustered = true;
        }
    }

    internal procedure CalculateEndDate()
    var
    begin
        // Whichever date is lowest is our actual 'end' date. Weird API
        if (Rec."Subscription Cancelled At" <> 0DT) or
          (Rec."Subscription Ended At" <> 0DT) or
          (Rec."Subscription Failed At" <> 0DT) and
          (Rec."Subscription End Date" = 0DT)
        then begin
            if Rec."Subscription Ended At" <> 0DT then
                Rec."Subscription End Date" := Rec."Subscription Ended At";
            if Rec."Subscription Failed At" <> 0DT then
                if (Rec."Subscription End Date" = 0DT) or (Rec."Subscription Failed At" < Rec."Subscription End Date") then
                    Rec."Subscription End Date" := Rec."Subscription Failed At";
            if Rec."Subscription Cancelled At" <> 0DT then
                if (Rec."Subscription End Date" = 0DT) or (Rec."Subscription Cancelled At" < Rec."Subscription End Date") then
                    Rec."Subscription End Date" := Rec."Subscription Cancelled At";
        end;
    end;

    internal procedure IsTestSubscription(): Boolean
    var
        SPBPLLicenseUtilities: Codeunit "SPBPL License Utilities";
    begin
        exit(Rec."Entry Id" = SPBPLLicenseUtilities.GetTestProductAppId());
    end;
}
