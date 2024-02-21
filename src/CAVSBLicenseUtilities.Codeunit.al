codeunit 71033 "CAVSB License Utilities"
{
    internal procedure GetTestProductAppId(): Guid
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.Id);
    end;

    internal procedure GetTestProductKey(SPBExtensionLicense: Record "CAVSB Extension License"): Text
    var
        LicensePlatform: Interface "CAVSB ILicenseCommunicator2";
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";
        exit(LicensePlatform.GetTestProductKey());
    end;

    [Obsolete('Use new Events in CAVSB Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLaunchProductUrl(var SPBExtensionLicense: Record "CAVSB Extension License"; var IsHandled: Boolean)
    begin
    end;
}
