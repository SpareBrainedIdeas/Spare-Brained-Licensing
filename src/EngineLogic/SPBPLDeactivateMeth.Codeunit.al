codeunit 71046 "CAVSB Deactivate Meth"
{
    internal procedure Deactivate(var SPBExtensionLicense: Record "CAVSB Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    begin
        DoDeactivate(SPBExtensionLicense, ByPlatform);
    end;

    local procedure DoDeactivate(var SPBExtensionLicense: Record "CAVSB Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    var
        CAVSBEvents: Codeunit "CAVSB Events";
        CAVSBIsoStoreManager: Codeunit "CAVSB IsoStore Manager";
        CAVSBTelemetry: Codeunit "CAVSB Telemetry";
        LicensePlatformV2: Interface "CAVSB ILicenseCommunicator2";
        DeactivationProblemErr: Label 'There was an issue in contacting the licensing server to deactivate this license.  Contact %1 for assistance.', Comment = '%1 is the App Publisher name';
        AppInfo: ModuleInfo;
        ResponseBody: Text;
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        SPBExtensionLicense.Validate(Activated, false);
        SPBExtensionLicense.Modify();
        CAVSBIsoStoreManager.UpdateOrCreateIsoStorage(SPBExtensionLicense);
        Commit();  // if calling the API fails, the local should still be marked as deactivated

        if not ByPlatform then begin
            LicensePlatformV2 := SPBExtensionLicense."License Platform";
            if not LicensePlatformV2.CallAPIForDeactivation(SPBExtensionLicense, ResponseBody) then begin
                if GuiAllowed() then
                    Error(DeactivationProblemErr, AppInfo.Publisher);
            end else
                DeactivationSuccess := true;
            CAVSBTelemetry.LicensePlatformDeactivation(SPBExtensionLicense);
            CAVSBEvents.OnAfterLicenseDeactivatedByPlatform(SPBExtensionLicense, ResponseBody);
        end else begin
            CAVSBTelemetry.LicenseDeactivation(SPBExtensionLicense);
            CAVSBEvents.OnAfterLicenseDeactivated(SPBExtensionLicense);
        end;
    end;
}