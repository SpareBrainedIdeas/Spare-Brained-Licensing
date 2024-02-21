codeunit 71264327 "CAVSB Activate Meth"
{
    Access = Internal;

    internal procedure Activate(var CAVExtensionLicense: Record "CAVSB Extension License") ActivationSuccess: Boolean
    var
        CAVSBTelemetry: Codeunit "CAVSB Telemetry";
        ResponseBody: Text;
    begin
        ActivationSuccess := CheckPlatformCanActivate(CAVExtensionLicense, ResponseBody);
        if ActivationSuccess then
            DoActivationInLocalSystem(CAVExtensionLicense);

        if ActivationSuccess then
            CAVSBTelemetry.LicenseActivation(CAVExtensionLicense)
        else
            CAVSBTelemetry.LicenseActivationFailure(CAVExtensionLicense);

        OnAfterActivate(CAVExtensionLicense);
    end;

    local procedure CheckPlatformCanActivate(var CAVExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text) ActivationSuccess: Boolean
    var
        LicensePlatform: Interface "CAVSB ILicenseCommunicator";
        LicensePlatformV2: Interface "CAVSB ILicenseCommunicator2";
        ActivationFailureErr: Label 'An error occured validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        NoRemainingUsesErr: Label 'There are no remaining uses of that license key to assign to this installation.';
        AppInfo: ModuleInfo;
    begin
        LicensePlatform := CAVExtensionLicense."License Platform";
        LicensePlatformV2 := CAVExtensionLicense."License Platform";
        // We'll want the App info for events / errors:
        NavApp.GetModuleInfo(CAVExtensionLicense."Extension App Id", AppInfo);

        if LicensePlatformV2.CallAPIForActivation(CAVExtensionLicense, ResponseBody) then begin
            if LicensePlatformV2.ClientSideLicenseCount(CAVExtensionLicense) then begin
                if LicensePlatform.CheckAPILicenseCount(CAVExtensionLicense, ResponseBody) then
                    ActivationSuccess := true
                else
                    if GuiAllowed() then
                        Error(NoRemainingUsesErr)
                    else
                        ActivationSuccess := false;  // Yes, default, but being explicit for clarity/future-proofing
            end else
                // if the Activation is Server Side, then the activation would have failed on a count issue
                ActivationSuccess := true;
            LicensePlatform.PopulateSubscriptionFromResponse(CAVExtensionLicense, ResponseBody);
        end else
            // In case of a malformed Implementation where the user is given no errors by the API call CU, we'll have a failsafe one here
            if GuiAllowed() then
                Error(ActivationFailureErr, AppInfo.Publisher)
            else
                ActivationSuccess := false; // Yes, default, but being explicit for clarity/future-proofing
    end;

    local procedure DoActivationInLocalSystem(var CAVExtensionLicense: Record "CAVSB Extension License"): Boolean
    var
        CAVSBEvents: Codeunit "CAVSB Events";
        CAVSBIsoStoreManager: Codeunit "CAVSB IsoStore Manager";
        LicenseKeyExpiredErr: Label 'The License Key provided has already expired due to a Subscription End.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        AppInfo: ModuleInfo;
    begin
        // We'll want the App info for events / errors:
        NavApp.GetModuleInfo(CAVExtensionLicense."Extension App Id", AppInfo);

        if (CAVExtensionLicense."Subscription End Date" <> 0DT) and
          (CAVExtensionLicense."Subscription End Date" < CurrentDateTime)
        then begin
            CAVExtensionLicense.Activated := false;
            CAVExtensionLicense.Modify();
            Commit();
            CAVSBEvents.OnAfterActivationFailure(CAVExtensionLicense, AppInfo);
            if GuiAllowed() then
                Error(LicenseKeyExpiredErr, AppInfo.Publisher);
        end else begin
            CAVExtensionLicense.Modify();
            Commit();
            CAVSBEvents.OnAfterActivationSuccess(CAVExtensionLicense, AppInfo);
        end;

        // Now pop the details into IsolatedStorage
        CAVSBIsoStoreManager.UpdateOrCreateIsoStorage(CAVExtensionLicense);
        exit(CAVExtensionLicense.Activated);
    end;

    local procedure OnAfterActivate(var CAVExtensionLicense: Record "CAVSB Extension License");
    var
        CAVSBEvents: Codeunit "CAVSB Events";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetModuleInfo(CAVExtensionLicense."Extension App Id", AppInfo);
        CAVSBEvents.OnAfterActivationSuccess(CAVExtensionLicense, AppInfo);
    end;
}
