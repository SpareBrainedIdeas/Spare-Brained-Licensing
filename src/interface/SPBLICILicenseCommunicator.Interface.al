interface "SPBPL ILicenseCommunicator"
{
    procedure CallAPIForVerification(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean) ResultOK: Boolean;

    procedure ReportPossibleMisuse(SPBExtensionLicense: Record "SPBPL Extension License");

    procedure PopulateSubscriptionFromResponse(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text);

    procedure CheckAPILicenseCount(var SPBExtensionLicense: Record "SPBPL Extension License"; ResponseBody: Text): Boolean

    procedure SampleKeyFormatText(): Text;
}
