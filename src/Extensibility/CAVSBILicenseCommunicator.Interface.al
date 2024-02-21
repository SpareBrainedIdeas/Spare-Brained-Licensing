interface "CAVSB ILicenseCommunicator"
{
    procedure CallAPIForVerification(var CAVExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean) ResultOK: Boolean;

    procedure ReportPossibleMisuse(CAVExtensionLicense: Record "CAVSB Extension License");

    procedure PopulateSubscriptionFromResponse(var CAVExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text);

    procedure CheckAPILicenseCount(var CAVExtensionLicense: Record "CAVSB Extension License"; ResponseBody: Text): Boolean

    procedure SampleKeyFormatText(): Text;
}