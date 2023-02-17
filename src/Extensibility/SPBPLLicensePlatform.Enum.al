enum 71033 "SPBPL License Platform" implements "SPBPL ILicenseCommunicator", "SPBPL ILicenseCommunicator2"
{
    Extensible = true;
    DefaultImplementation = "SPBPL ILicenseCommunicator" = "SPBPL Gumroad Communicator", "SPBPL ILicenseCommunicator2" = "SPBPL Gumroad Communicator";

    value(0; Gumroad)
    {
        Caption = 'Gumroad';
        Implementation = "SPBPL ILicenseCommunicator" = "SPBPL Gumroad Communicator", "SPBPL ILicenseCommunicator2" = "SPBPL Gumroad Communicator";
    }
    value(1; LemonSqueezy)
    {
        Caption = 'LemonSqueezy';
        Implementation = "SPBPL ILicenseCommunicator" = "SPBPL LemonSqueezy Comm.", "SPBPL ILicenseCommunicator2" = "SPBPL LemonSqueezy Comm.";
    }
}
