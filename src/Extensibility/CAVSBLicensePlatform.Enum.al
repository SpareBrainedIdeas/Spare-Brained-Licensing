enum 71033 "CAVSB License Platform" implements "CAVSB ILicenseCommunicator", "CAVSB ILicenseCommunicator2"
{
    Extensible = true;
    DefaultImplementation = "CAVSB ILicenseCommunicator" = "CAVSB Gumroad Communicator", "CAVSB ILicenseCommunicator2" = "CAVSB Gumroad Communicator";

    value(0; Gumroad)
    {
        Caption = 'Gumroad';
        Implementation = "CAVSB ILicenseCommunicator" = "CAVSB Gumroad Communicator", "CAVSB ILicenseCommunicator2" = "CAVSB Gumroad Communicator";
    }
    value(1; LemonSqueezy)
    {
        Caption = 'LemonSqueezy';
        Implementation = "CAVSB ILicenseCommunicator" = "CAVSB LemonSqueezy Comm.", "CAVSB ILicenseCommunicator2" = "CAVSB LemonSqueezy Comm.";
    }
}
