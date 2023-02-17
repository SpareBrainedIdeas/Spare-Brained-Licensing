interface "SPBPL ILicenseCommunicator2"
{
    procedure CallAPIForActivation(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text) ResultOK: Boolean;

    procedure CallAPIForDeactivation(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text) ResultOK: Boolean;

    procedure ClientSideDeactivationPossible(var SPBExtensionLicense: Record "SPBPL Extension License"): Boolean;

    procedure ClientSideLicenseCount(var SPBExtensionLicense: Record "SPBPL Extension License"): Boolean;

    procedure GetTestProductUrl(): Text;

    procedure GetTestProductId(): Text;

    procedure GetTestProductKey(): Text;

    procedure GetTestSupportUrl(): Text;

    procedure GetTestBillingEmail(): Text;
}
