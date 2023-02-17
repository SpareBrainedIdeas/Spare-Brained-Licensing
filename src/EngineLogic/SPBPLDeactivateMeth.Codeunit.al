codeunit 71046 "SPBPL Deactivate Meth"
{
    internal procedure Deactivate(var SPBExtensionLicense: Record "SPBPL Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    begin
        DoDeactivate(SPBExtensionLicense, ByPlatform);
    end;

    local procedure DoDeactivate(var SPBExtensionLicense: Record "SPBPL Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    var
        SPBPLEvents: Codeunit "SPBPL Events";
        SPBPLIsoStoreManager: Codeunit "SPBPL IsoStore Manager";
        SPBPLTelemetry: Codeunit "SPBPL Telemetry";
        LicensePlatformV2: Interface "SPBPL ILicenseCommunicator2";
        DeactivationProblemErr: Label 'There was an issue in contacting the licensing server to deactivate this license.  Contact %1 for assistance.', Comment = '%1 is the App Publisher name';
        AppInfo: ModuleInfo;
        ResponseBody: Text;
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        SPBExtensionLicense.Validate(Activated, false);
        SPBExtensionLicense.Modify();
        SPBPLIsoStoreManager.UpdateOrCreateIsoStorage(SPBExtensionLicense);
        Commit();  // if calling the API fails, the local should still be marked as deactivated

        if not ByPlatform then begin
            LicensePlatformV2 := SPBExtensionLicense."License Platform";
            if not LicensePlatformV2.CallAPIForDeactivation(SPBExtensionLicense, ResponseBody) then begin
                if GuiAllowed() then
                    Error(DeactivationProblemErr, AppInfo.Publisher);
            end else
                DeactivationSuccess := true;
            SPBPLTelemetry.LicensePlatformDeactivation(SPBExtensionLicense);
            SPBPLEvents.OnAfterLicenseDeactivatedByPlatform(SPBExtensionLicense, ResponseBody);
        end else begin
            SPBPLTelemetry.LicenseDeactivation(SPBExtensionLicense);
            SPBPLEvents.OnAfterLicenseDeactivated(SPBExtensionLicense);
        end;
    end;
}