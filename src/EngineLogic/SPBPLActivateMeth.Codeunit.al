codeunit 71045 "SPBPL Activate Meth"
{
    Access = Internal;

    internal procedure Activate(var SPBExtensionLicense: Record "SPBPL Extension License") ActivationSuccess: Boolean
    var
        SPBPLTelemetry: Codeunit "SPBPL Telemetry";
        ResponseBody: Text;
    begin
        ActivationSuccess := CheckPlatformCanActivate(SPBExtensionLicense, ResponseBody);
        if ActivationSuccess then
            DoActivationInLocalSystem(SPBExtensionLicense);

        if ActivationSuccess then
            SPBPLTelemetry.LicenseActivation(SPBExtensionLicense)
        else
            SPBPLTelemetry.LicenseActivationFailure(SPBExtensionLicense);

        OnAfterActivate(SPBExtensionLicense);
    end;

    local procedure CheckPlatformCanActivate(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text) ActivationSuccess: Boolean
    var
        LicensePlatform: Interface "SPBPL ILicenseCommunicator";
        ActivationFailureErr: Label 'An error occured validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        NoRemainingUsesErr: Label 'There are no remaining uses of that license key to assign to this installation.';
        AppInfo: ModuleInfo;
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";
        // We'll want the App info for events / errors:
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        if LicensePlatform.CallAPIForActivation(SPBExtensionLicense, ResponseBody) then begin
            if LicensePlatform.ClientSideLicenseCount(SPBExtensionLicense) then begin
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

    local procedure DoActivationInLocalSystem(var SPBExtensionLicense: Record "SPBPL Extension License"): Boolean
    var
        SPBPLEvents: Codeunit "SPBPL Events";
        SPBPLIsoStoreManager: Codeunit "SPBPL IsoStore Manager";
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
            SPBPLEvents.OnAfterActivationFailure(SPBExtensionLicense, AppInfo);
            if GuiAllowed() then
                Error(LicenseKeyExpiredErr, AppInfo.Publisher);
        end else begin
            SPBExtensionLicense.Modify();
            Commit();
            SPBPLEvents.OnAfterActivationSuccess(SPBExtensionLicense, AppInfo);
        end;

        // Now pop the details into IsolatedStorage
        SPBPLIsoStoreManager.UpdateOrCreateIsoStorage(SPBExtensionLicense);
        exit(SPBExtensionLicense.Activated);
    end;

    local procedure OnAfterActivate(var SPBExtensionLicense: Record "SPBPL Extension License");
    var
        SPBPLEvents: Codeunit "SPBPL Events";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
        SPBPLEvents.OnAfterActivationSuccess(SPBExtensionLicense, AppInfo);
    end;
}