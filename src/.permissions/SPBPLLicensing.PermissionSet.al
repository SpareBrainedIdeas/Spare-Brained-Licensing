permissionset 71033 "SPBPL Licensing"
{
    Assignable = true;
    Caption = 'Spare Brained Licensing Admin';
    Permissions = table "SPBPL Extension License" = X,
        tabledata "SPBPL Extension License" = RMI,
        codeunit "SPBPL Activate Meth" = X,
        codeunit "SPBPL Check Active" = X,
        codeunit "SPBPL Check Active Meth" = X,
        codeunit "SPBPL Deactivate Meth" = X,
        codeunit "SPBPL Environment Watcher" = X,
        codeunit "SPBPL Events" = X,
        codeunit "SPBPL Extension Registration" = X,
        codeunit "SPBPL Gumroad Communicator" = X,
        codeunit "SPBPL IsoStore Manager" = X,
        codeunit "SPBPL LemonSqueezy Comm." = X,
        codeunit "SPBPL License Utilities" = X,
        codeunit "SPBPL Licensing Install" = X,
        codeunit "SPBPL Upgrade" = X,
        codeunit "SPBPL Version Check" = X,
        page "SPBPL Extension Licenses" = X,
        page "SPBPL License Activation" = X;
}