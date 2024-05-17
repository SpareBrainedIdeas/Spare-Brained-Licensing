enum 71033575 "SPBLIC License Platform" implements "SPBLIC ILicenseCommunicator", "SPBLIC ILicenseCommunicator2"
{
    Extensible = true;
    DefaultImplementation = "SPBLIC ILicenseCommunicator" = "SPBLIC Gumroad Communicator", "SPBLIC ILicenseCommunicator2" = "SPBLIC Gumroad Communicator";

    value(0; Gumroad)
    {
        Caption = 'Gumroad';
        Implementation = "SPBLIC ILicenseCommunicator" = "SPBLIC Gumroad Communicator", "SPBLIC ILicenseCommunicator2" = "SPBLIC Gumroad Communicator";
    }
    value(1; LemonSqueezy)
    {
        Caption = 'LemonSqueezy';
        Implementation = "SPBLIC ILicenseCommunicator" = "SPBLIC LemonSqueezy Comm.", "SPBLIC ILicenseCommunicator2" = "SPBLIC LemonSqueezy Comm.";
    }
}
