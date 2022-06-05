permissionset 71035 "SPBPL Licensing RO"
{
    Assignable = true;
    Caption = 'SPBPL Licensing RO';
    Permissions =
        table "SPBPL Extension License" = X,
        tabledata "SPBPL Extension License" = RI,
        codeunit "SPBPL License Management" = X,
        codeunit "SPBPL Licensing Install" = X,
        codeunit "SPBPL License Utilities" = X,
        codeunit "SPBPL IsoStore Manager" = X,
        codeunit "SPBPL Gumroad Communicator" = X,
        codeunit "SPBPL Extension Registration" = X,
        page "SPBPL License Activation" = X,
        page "SPBPL Extension Licenses" = X;
}
