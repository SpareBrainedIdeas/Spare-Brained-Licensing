permissionset 71034 "SPBPL Licensing"
{
    Assignable = true;
    Caption = 'Spare Brained Licensing Admin';
    Permissions =
        table "SPBPL Extension License" = X,
        tabledata "SPBPL Extension License" = RMI,
        codeunit "SPBPL Gumroad Communicator" = X,
        codeunit "SPBPL Licensing Install" = X,
        codeunit "SPBPL License Management" = X,
        codeunit "SPBPL License Utilities" = X,
        page "SPBPL License Activation" = X,
        page "SPBPL Extension Licenses" = X;
}
