interface "SPBPL ILicenseCommunicator"
{
    procedure CallAPIForActivation(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text) ResultOK: Boolean;

    procedure CallAPIForVerification(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean) ResultOK: Boolean;

    procedure CallAPIForDeactivation(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text) ResultOK: Boolean;

    procedure ReportPossibleMisuse(SPBExtensionLicense: Record "SPBPL Extension License");

    procedure PopulateSubscriptionFromResponse(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text);

    procedure ClientSideDeactivationPossible(var SPBExtensionLicense: Record "SPBPL Extension License"): Boolean;

    procedure ClientSideLicenseCount(var SPBExtensionLicense: Record "SPBPL Extension License"): Boolean;

    procedure CheckAPILicenseCount(var SPBExtensionLicense: Record "SPBPL Extension License"; ResponseBody: Text): Boolean

    procedure SampleKeyFormatText(): Text;


    procedure GetTestProductUrl(): Text;

    procedure GetTestProductId(): Text;

    procedure GetTestProductKey(): Text;

    procedure GetTestSupportUrl(): Text;

    procedure GetTestBillingEmail(): Text;
}
