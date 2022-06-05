enum 71033 "SPBPL License Platform" implements "SPBPL ILicenseCommunicator"
{
    Extensible = true;

    value(0; Gumroad)
    {
        Caption = 'Gumroad';
        Implementation = "SPBPL ILicenseCommunicator" = "SPBPL Gumroad Communicator";
    }

}
