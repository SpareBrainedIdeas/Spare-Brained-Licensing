codeunit 71036 "SPBPL License Management"
{
    Permissions = tabledata "SPBPL Extension License" = RIM;

    var
        SPBLicenseUtilities: Codeunit "SPBPL License Utilities";

    internal procedure CheckSupportedVersion(minVersion: Version)
    var
        VersionUpdateRequiredErr: Label 'To install this Extension, you need to update %1 to at least version %2.', Comment = '%1 is the name of extension, %2 is the version number';
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if AppInfo.AppVersion < minVersion then
            if GuiAllowed then
                Error(VersionUpdateRequiredErr, AppInfo.Name, minVersion);
    end;


    internal procedure ActivateFromWizard(var SPBExtensionLicense: Record "SPBPL Extension License"): Boolean
    var
        ResponseBody: Text;
        NoRemainingUsesErr: Label 'There are no remaining uses of that license key to assign to this installation.';
        LicensePlatform: Interface "SPBPL ILicenseCommunicator";
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";
        // We call first WITHOUT incrementing the use count to check current use count
        if LicensePlatform.CallAPIForVerification(SPBExtensionLicense, ResponseBody, false) then
            if LicensePlatform.CheckAPILicenseCount(SPBExtensionLicense, ResponseBody) then
                exit(ActivateExtension(SPBExtensionLicense, ResponseBody))
            else
                if GuiAllowed() then
                    Error(NoRemainingUsesErr);
    end;

    internal procedure LaunchActivation(var SPBExtensionLicense: Record "SPBPL Extension License")
    var
        SPBLicenseActivationWizard: Page "SPBPL License Activation";
    begin
        Clear(SPBLicenseActivationWizard);
        SPBExtensionLicense.SetRecFilter();
        SPBLicenseActivationWizard.SetTableView(SPBExtensionLicense);
        SPBLicenseActivationWizard.RunModal();
    end;

    internal procedure VerifyActiveLicense(var SPBExtensionLicense: Record "SPBPL Extension License")
    begin
        if not SPBExtensionLicense.Activated then
            exit;

        if not CheckIfActive(SPBExtensionLicense) then begin
            SPBExtensionLicense.Validate(Activated, false);
            SPBExtensionLicense.Modify();
        end;
    end;

    internal procedure CheckIfActive(var SPBExtensionLicense: Record "SPBPL Extension License"): Boolean
    var
        SPBIsoStoreManager: Codeunit "SPBPL IsoStore Manager";
        EnvironmentInformation: Codeunit "Environment Information";
        GraceExpiringMsg: Label 'Today is the last trial day for %1. Please purchase a License Key and Activate the subscription to continue use.', Comment = '%1 is the name of the Extension';
        DaysGraceTok: Label '<+%1D>', Comment = '%1 is the number of days';
        IsoActive: Boolean;
        ResponseBody: Text;
        GraceEndDate: Date;
        InstallDateTime: DateTime;
        LastCheckDateTime: DateTime;
        IsoDatetime: DateTime;
        IsoNumber: Integer;
        LicensePlatform: Interface "SPBPL ILicenseCommunicator";
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";

        // if the subscription isn't active, check if we're in the 'grace' preinstall window, which always includes the first day of use
        if not SPBExtensionLicense.Activated then begin
            Evaluate(InstallDateTime, SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'installDate'));
            Evaluate(IsoNumber, SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'preactivationDays'));
            if IsoNumber > 0 then
                GraceEndDate := CalcDate(StrSubstNo(DaysGraceTok, IsoNumber), DT2Date(InstallDateTime))
            else
                if (EnvironmentInformation.IsSandbox() and (IsoNumber < 0)) then
                    // -1 days grace for a Sandbox means it's unlimited use in sandboxes, even if not activated.
                    exit(true)
                else
                    GraceEndDate := Today;
            if (GraceEndDate = Today) and GuiAllowed then
                Message(GraceExpiringMsg, SPBExtensionLicense."Extension Name");
            exit(GraceEndDate > Today);
        end;

        Evaluate(LastCheckDateTime, SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'lastCheckDate'));
        if ((Today() - DT2Date(LastCheckDateTime)) > 0) then begin
            if LicensePlatform.CallAPIForVerification(SPBExtensionLicense, ResponseBody, false) then begin
                // This may update the End Dates - note: may or may not call .Modify
                LicensePlatform.PopulateSubscriptionFromResponse(SPBExtensionLicense, ResponseBody);
                SPBExtensionLicense.Modify();
            end;
            DoVersionCheck(SPBExtensionLicense);
            SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'lastCheckDate', Format(CurrentDateTime, 0, 9));
        end;

        // if the subscription ran out
        if (SPBExtensionLicense."Subscription End Date" < CurrentDateTime) and
          (SPBExtensionLicense."Subscription End Date" <> 0DT)
        then
            exit(false);


        // if the record version IS active, then let's crosscheck against isolated storage
        Evaluate(IsoActive, SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'active'));
        if not IsoActive then
            LicensePlatform.ReportPossibleMisuse(SPBExtensionLicense);

        // Check Record end date against IsoStorage end date
        Evaluate(IsoDatetime, SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'endDate'));
        if IsoDatetime <> 0DT then
            // Only checking at the date level in case of time zone nonsense
            if DT2Date(IsoDatetime) <> DT2Date(SPBExtensionLicense."Subscription End Date") then
                LicensePlatform.ReportPossibleMisuse(SPBExtensionLicense);

        // Finally, all things checked out
        exit(true);
    end;

    local procedure ActivateExtension(var SPBExtensionLicense: Record "SPBPL Extension License"; ResponseBody: Text): Boolean
    var
        LicensePlatform: Interface "SPBPL ILicenseCommunicator";
        AppInfo: ModuleInfo;
        ActivationFailureErr: Label 'An error occured validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        LicenseKeyExpiredErr: Label 'The License Key provided has already expired due to a Subscription End.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);

        // Note we're swapping the ResponseBody to the 2nd API call with the new info from the API!
        LicensePlatform := SPBExtensionLicense."License Platform";
        if LicensePlatform.CallAPIForVerification(SPBExtensionLicense, ResponseBody, true) then begin

            LicensePlatform.PopulateSubscriptionFromResponse(SPBExtensionLicense, ResponseBody);

            if (SPBExtensionLicense."Subscription End Date" <> 0DT) and
              (SPBExtensionLicense."Subscription End Date" < CurrentDateTime)
            then begin
                SPBExtensionLicense.Activated := false;
                SPBExtensionLicense.Modify();
                Commit();
                OnAfterActivationFailure(SPBExtensionLicense, AppInfo);
                if GuiAllowed() then
                    Error(LicenseKeyExpiredErr, AppInfo.Publisher);
            end else begin
                SPBExtensionLicense.Modify();
                Commit();
                OnAfterActivationSuccess(SPBExtensionLicense, AppInfo);
            end;

            // Now pop the details into IsolatedStorage
            SPBLicenseUtilities.UpdateOrCreateIsoStorage(SPBExtensionLicense);
            exit(SPBExtensionLicense.Activated);
        end;
    end;

    internal procedure DoVersionCheck(var SPBExtensionLicense: Record "SPBPL Extension License")
    var
        UserTask: Record "User Task";
        SubjectTok: Label 'Update Extension: %1', Comment = '%1 is Extension Name';
        DocsTok: Label 'https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/tenant-admin-center-manage-apps#get-an-overview-and-check-for-updates', Locked = true;
        ApiHttpClient: HttpClient;
        ApiHttpRequestMessage: HttpRequestMessage;
        ApiHttpResponseMessage: HttpResponseMessage;
        VersionResponseBody: Text;
        IsHandled: Boolean;
        LatestVersion: Version;
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if SPBExtensionLicense."Version Check URL" = '' then
            exit;

        ApiHttpRequestMessage.SetRequestUri(SPBExtensionLicense."Version Check URL");
        ApiHttpRequestMessage.Method('GET');

        if ApiHttpClient.Send(ApiHttpRequestMessage, ApiHttpResponseMessage) then begin
            if ApiHttpResponseMessage.IsSuccessStatusCode then begin
                ApiHttpResponseMessage.Content.ReadAs(VersionResponseBody);
                LatestVersion := Version.Create(VersionResponseBody);
                if (AppInfo.AppVersion < LatestVersion) then begin
                    SPBExtensionLicense."Update Available" := true;
                    SPBExtensionLicense.Modify();

                    OnBeforeVersionCheckUpgradeAvailable(SPBExtensionLicense, LatestVersion, IsHandled);
                    if IsHandled then
                        exit;

                    UserTask.Init();
                    UserTask.Title := StrSubstNo(SubjectTok, AppInfo.Name);
                    UserTask.SetDescription(DocsTok);
                    if not IsNullGuid(SPBExtensionLicense."Activated By") then
                        UserTask."Assigned To" := SPBExtensionLicense."Activated By";
                    UserTask."Due DateTime" := CurrentDateTime;
                    UserTask."Start DateTime" := CurrentDateTime;
                    UserTask."Object Type" := UserTask."Object Type"::Page;
                    UserTask."Object ID" := Page::"SPBPL Extension Licenses";
                    UserTask.Insert(true);
                end;
            end else
                OnAfterVersionCheckFailure(SPBExtensionLicense, ApiHttpResponseMessage);
        end else
            OnAfterVersionCheckFailure(SPBExtensionLicense, ApiHttpResponseMessage);
    end;

    internal procedure DeactivateExtension(var SPBExtensionLicense: Record "SPBPL Extension License"): Boolean
    var
        DeactivationWarningQst: Label 'This will deactivate this license in this Business Central instance, but you will need to contact the Publisher to release the assigned license. \ \Are you sure you want to deactivate this license?';
    begin
        if Confirm(DeactivationWarningQst, false) then begin
            DeactivateLicense(SPBExtensionLicense)
        end;
    end;


    internal procedure DeactivateLicense(var SPBExtensionLicense: Record "SPBPL Extension License")
    var
        SPBLicenseUtilities: Codeunit "SPBPL License Utilities";
    begin
        SPBExtensionLicense.Validate(Activated, false);
        SPBExtensionLicense.Modify();
        SPBLicenseUtilities.UpdateOrCreateIsoStorage(SPBExtensionLicense);
        OnAfterLicenseDeactivated(SPBExtensionLicense);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Triggers", 'OnAfterCopyEnvironmentPerDatabase', '', false, false)]
    local procedure DeactivateLicensesWhenEnvironmentCopied(DestinationEnvironmentType: Option Production,Sandbox)
    var
        SPBExtensionLicense: Record "SPBPL Extension License";
    begin
        if SPBExtensionLicense.FindSet(true) then
            repeat
                if DestinationEnvironmentType = DestinationEnvironmentType::Sandbox then begin
                    // Reset all licenses to Sandbox grace
                    if SPBExtensionLicense."Sandbox Grace Days" <> 0 then
                        SPBExtensionLicense."Trial Grace End Date" := CalcDate(StrSubstNo('<+%1D>', SPBExtensionLicense."Sandbox Grace Days"), Today);
                    DeactivateLicense(SPBExtensionLicense);
                end else begin
                    // Deactive the licenses in general
                    DeactivateLicense(SPBExtensionLicense);
                end;
            until SPBExtensionLicense.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLicenseDeactivated(var SPBExtensionLicense: Record "SPBPL Extension License")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterActivationFailure(var SPBExtensionLicense: Record "SPBPL Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVersionCheckUpgradeAvailable(var SPBExtensionLicense: Record "SPBPL Extension License"; var LatestVersion: Version; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterActivationSuccess(var SPBExtensionLicense: Record "SPBPL Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVersionCheckFailure(var SPBExtensionLicense: Record "SPBPL Extension License"; var ApiHttpResponseMessage: HttpResponseMessage)
    begin
    end;

}
