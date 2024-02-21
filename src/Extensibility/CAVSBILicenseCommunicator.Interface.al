interface "CAVSB ILicenseCommunicator"
{
    procedure CallAPIForVerification(var SPBExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean) ResultOK: Boolean;

    procedure ReportPossibleMisuse(SPBExtensionLicense: Record "CAVSB Extension License");

    procedure PopulateSubscriptionFromResponse(var SPBExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text);

    procedure CheckAPILicenseCount(var SPBExtensionLicense: Record "CAVSB Extension License"; ResponseBody: Text): Boolean

    procedure SampleKeyFormatText(): Text;
}