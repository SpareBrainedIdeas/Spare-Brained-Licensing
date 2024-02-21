codeunit 71045 "CAVSB Activate Meth"
{
    Access = Internal;

    internal procedure Activate(var SPBExtensionLicense: Record "CAVSB Extension License") ActivationSuccess: Boolean
    var
        CAVSBTelemetry: Codeunit "CAVSB Telemetry";
        ResponseBody: Text;
    begin
        ActivationSuccess := CheckPlatformCanActivate(SPBExtensionLicense, ResponseBody);
        if ActivationSuccess then
            DoActivationInLocalSystem(SPBExtensionLicense);

        if ActivationSuccess then
            CAVSBTelemetry.LicenseActivation(SPBExtensionLicense)
        else
            CAVSBTelemetry.LicenseActivationFailure(SPBExtensionLicense);

        OnAfterActivate(SPBExtensionLicense);
    end;

    local procedure CheckPlatformCanActivate(var SPBExtensionLicense: Record "CAVSB Extension License"; var ResponseBody: Text) ActivationSuccess: Boolean
    var
        LicensePlatform: Interface "CAVSB ILicenseCommunicator";
        LicensePlatformV2: Interface "CAVSB ILicenseCommunicator2";
        ActivationFailureErr: Label 'An error occured validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        NoRemainingUsesErr: Label 'There are no remaining uses of that license key to assign to this installation.';
        AppInfo: ModuleInfo;
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";
        LicensePlatformV2 := SPBExtensionLicense."License Platform";
        // We'll want the App info for events / errors:
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        if LicensePlatformV2.CallAPIForActivation(SPBExtensionLicense, ResponseBody) then begin
            if LicensePlatformV2.ClientSideLicenseCount(SPBExtensionLicense) then begin
                if LicensePlatform.CheckAPILicenseCount(SPBExtensionLicense, ResponseBody) then
                    ActivationSuccess := true
                else
                    if GuiAllowed() then
                        Error(NoRemainingUsesErr)
                    else
                        ActivationSuccess := false;  // Yes, default, but being explicit for clarity/future-proofing
            end else
                // if the Activation is Server Side, then the activation would have failed on a count issue
                ActivationSuccess := true;
            LicensePlatform.PopulateSubscriptionFromResponse(SPBExtensionLicense, ResponseBody);
        end else
            // In case of a malformed Implementation where the user is given no errors by the API call CU, we'll have a failsafe one here
            if GuiAllowed() then
                Error(ActivationFailureErr, AppInfo.Publisher)
            else
                ActivationSuccess := false; // Yes, default, but being explicit for clarity/future-proofing
    end;

    local procedure DoActivationInLocalSystem(var SPBExtensionLicense: Record "CAVSB Extension License"): Boolean
    var
        CAVSBEvents: Codeunit "CAVSB Events";
        CAVSBIsoStoreManager: Codeunit "CAVSB IsoStore Manager";
        LicenseKeyExpiredErr: Label 'The License Key provided has already expired due to a Subscription End.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        AppInfo: ModuleInfo;
    begin
        // We'll want the App info for events / errors:
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        if (SPBExtensionLicense."Subscription End Date" <> 0DT) and
          (SPBExtensionLicense."Subscription End Date" < CurrentDateTime)
        then begin
            SPBExtensionLicense.Activated := false;
            SPBExtensionLicense.Modify();
            Commit();
            CAVSBEvents.OnAfterActivationFailure(SPBExtensionLicense, AppInfo);
            if GuiAllowed() then
                Error(LicenseKeyExpiredErr, AppInfo.Publisher);
        end else begin
            SPBExtensionLicense.Modify();
            Commit();
            CAVSBEvents.OnAfterActivationSuccess(SPBExtensionLicense, AppInfo);
        end;

        // Now pop the details into IsolatedStorage
        CAVSBIsoStoreManager.UpdateOrCreateIsoStorage(SPBExtensionLicense);
        exit(SPBExtensionLicense.Activated);
    end;

    local procedure OnAfterActivate(var SPBExtensionLicense: Record "CAVSB Extension License");
    var
        CAVSBEvents: Codeunit "CAVSB Events";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
        CAVSBEvents.OnAfterActivationSuccess(SPBExtensionLicense, AppInfo);
    end;
}
