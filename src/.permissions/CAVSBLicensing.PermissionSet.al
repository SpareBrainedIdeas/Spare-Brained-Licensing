permissionset 71264323 "CAVSB Licensing"
{
    Assignable = true;
    Caption = 'Spare Brained Licensing Admin';
    Permissions = table "CAVSB Extension License" = X,
        tabledata "CAVSB Extension License" = RMI,
        codeunit "CAVSB Activate Meth" = X,
        codeunit "CAVSB Check Active" = X,
        codeunit "CAVSB Check Active Meth" = X,
        codeunit "CAVSB Deactivate Meth" = X,
        codeunit "CAVSB Environment Watcher" = X,
        codeunit "CAVSB Events" = X,
        codeunit "CAVSB Extension Registration" = X,
        codeunit "CAVSB Gumroad Communicator" = X,
        codeunit "CAVSB IsoStore Manager" = X,
        codeunit "CAVSB LemonSqueezy Comm." = X,
        codeunit "CAVSB License Utilities" = X,
        codeunit "CAVSB Licensing Install" = X,
        codeunit "CAVSB Telemetry" = X,
        codeunit "CAVSB Upgrade" = X,
        codeunit "CAVSB Version Check" = X,
        page "CAVSB Extension Licenses" = X,
        page "CAVSB License Activation" = X;
}