codeunit 71264329 "CAVSB Deactivate Meth"
{
    internal procedure Deactivate(var CAVExtensionLicense: Record "CAVSB Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    begin
        DoDeactivate(CAVExtensionLicense, ByPlatform);
    end;

    local procedure DoDeactivate(var CAVExtensionLicense: Record "CAVSB Extension License"; ByPlatform: Boolean) DeactivationSuccess: Boolean
    var
        CAVSBEvents: Codeunit "CAVSB Events";
        CAVSBIsoStoreManager: Codeunit "CAVSB IsoStore Manager";
        CAVSBTelemetry: Codeunit "CAVSB Telemetry";
        LicensePlatformV2: Interface "CAVSB ILicenseCommunicator2";
        DeactivationProblemErr: Label 'There was an issue in contacting the licensing server to deactivate this license.  Contact %1 for assistance.', Comment = '%1 is the App Publisher name';
        AppInfo: ModuleInfo;
        ResponseBody: Text;
    begin
        NavApp.GetModuleInfo(CAVExtensionLicense."Extension App Id", AppInfo);

        CAVExtensionLicense.Validate(Activated, false);
        CAVExtensionLicense.Modify();
        CAVSBIsoStoreManager.UpdateOrCreateIsoStorage(CAVExtensionLicense);
        Commit();  // if calling the API fails, the local should still be marked as deactivated

        if not ByPlatform then begin
            LicensePlatformV2 := CAVExtensionLicense."License Platform";
            if not LicensePlatformV2.CallAPIForDeactivation(CAVExtensionLicense, ResponseBody) then begin
                if GuiAllowed() then
                    Error(DeactivationProblemErr, AppInfo.Publisher);
            end else
                DeactivationSuccess := true;
            CAVSBTelemetry.LicensePlatformDeactivation(CAVExtensionLicense);
            CAVSBEvents.OnAfterLicenseDeactivatedByPlatform(CAVExtensionLicense, ResponseBody);
        end else begin
            CAVSBTelemetry.LicenseDeactivation(CAVExtensionLicense);
            CAVSBEvents.OnAfterLicenseDeactivated(CAVExtensionLicense);
        end;
    end;
}