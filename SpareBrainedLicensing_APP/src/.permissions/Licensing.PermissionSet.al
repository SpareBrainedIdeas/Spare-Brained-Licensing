permissionset 71033575 "SPBLIC Licensing"
{
    Assignable = true;
    Caption = 'Spare Brained Licensing Admin', MaxLength = 30;
    Permissions = table "SPBLIC Extension License" = X,
        table "SPBLIC IsoStore Map" = X,
        tabledata "SPBLIC Extension License" = RMI,
        tabledata "SPBLIC IsoStore Map" = RMI,
        codeunit "SPBLIC Activate Meth" = X,
        codeunit "SPBLIC Check Active" = X,
        codeunit "SPBLIC Check Active Meth" = X,
        codeunit "SPBLIC Deactivate Meth" = X,
        codeunit "SPBLIC Environment Watcher" = X,
        codeunit "SPBLIC Events" = X,
        codeunit "SPBLIC Extension Registration" = X,
        codeunit "SPBLIC Gumroad Communicator" = X,
        codeunit "SPBLIC IsoStore Manager" = X,
        codeunit "SPBLIC LemonSqueezy Comm." = X,
        codeunit "SPBLIC License Utilities" = X,
        codeunit "SPBLIC Licensing Install" = X,
        codeunit "SPBLIC Telemetry" = X,
        codeunit "SPBLIC Upgrade" = X,
        codeunit "SPBLIC Version Check" = X,
        page "SPBLIC Extension Licenses" = X,
        page "SPBLIC License Activation" = X;
}