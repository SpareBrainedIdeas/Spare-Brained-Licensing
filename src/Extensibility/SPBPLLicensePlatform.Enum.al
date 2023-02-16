enum 71033 "SPBPL License Platform" implements "SPBPL ILicenseCommunicator"
{
    Extensible = true;

    value(0; Gumroad)
    {
        Caption = 'Gumroad';
        Implementation = "SPBPL ILicenseCommunicator" = "SPBPL Gumroad Communicator";
    }
    value(1; LemonSqueezy)
    {
        Caption = 'LemonSqueezy';
        Implementation = "SPBPL ILicenseCommunicator" = "SPBPL LemonSqueezy Comm.";
    }
}
