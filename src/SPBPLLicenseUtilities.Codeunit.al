codeunit 71033 "SPBPL License Utilities"
{
    internal procedure GetTestProductAppId(): Guid
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.Id);
    end;

    internal procedure GetTestProductKey(SPBExtensionLicense: Record "SPBPL Extension License"): Text
    var
        LicensePlatform: Interface "SPBPL ILicenseCommunicator2";
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";
        exit(LicensePlatform.GetTestProductKey());
    end;

    [Obsolete('Use new Events in SPBPL Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLaunchProductUrl(var SPBExtensionLicense: Record "SPBPL Extension License"; var IsHandled: Boolean)
    begin
    end;
}
