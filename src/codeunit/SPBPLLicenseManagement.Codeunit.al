codeunit 71036 "SPBPL License Management"
{
    Permissions = tabledata "SPBPL Extension License" = RIM;

    var
        /* GumroadCommunicator: Codeunit "SPBPL Gumroad Communicator"; */
        SPBPLLicenseUtilities: Codeunit "SPBPL License Utilities";

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


    internal procedure ActivateFromWizard(var SPBPLExtensionLicense: Record "SPBPL Extension License"): Boolean
    var
        ResponseBody: Text;
        NoRemainingUsesErr: Label 'There are no remaining uses of that license key to assign to this installation.';
        LicensePlatform: Interface "SPBPL ILicenseCommunicator";
    begin
        LicensePlatform := SPBPLExtensionLicense."License Platform";
        // We call first WITHOUT incrementing the use count to check current use count
        if LicensePlatform.CallAPIForVerification(SPBPLExtensionLicense, ResponseBody, false) then
            if LicensePlatform.CheckAPILicenseCount(SPBPLExtensionLicense, ResponseBody) then
                exit(ActivateExtension(SPBPLExtensionLicense, ResponseBody))
            else
                if GuiAllowed() then
                    Error(NoRemainingUsesErr);
    end;

    internal procedure LaunchActivation(var SPBPLExtensionLicense: Record "SPBPL Extension License")
    var
        SPBPLLicenseActivationWizard: Page "SPBPL License Activation";
    begin
        Clear(SPBPLLicenseActivationWizard);
        SPBPLExtensionLicense.SetRecFilter();
        SPBPLLicenseActivationWizard.SetTableView(SPBPLExtensionLicense);
        SPBPLLicenseActivationWizard.RunModal();
    end;

    internal procedure VerifyActiveLicense(var SPBPLExtensionLicense: Record "SPBPL Extension License")
    begin
        if not SPBPLExtensionLicense.Activated then
            exit;

        if not CheckIfActive(SPBPLExtensionLicense) then begin
            SPBPLExtensionLicense.Validate(Activated, false);
            SPBPLExtensionLicense.Modify();
        end;
    end;

    internal procedure CheckIfActive(var SPBPLExtensionLicense: Record "SPBPL Extension License"): Boolean
    var
        SPBPLIsoStoreManager: Codeunit "SPBPL IsoStore Manager";
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
        LicensePlatform := SPBPLExtensionLicense."License Platform";

        // if the subscription isn't active, check if we're in the 'grace' preinstall window, which always includes the first day of use
        if not SPBPLExtensionLicense.Activated then begin
            Evaluate(InstallDateTime, SPBPLIsoStoreManager.GetAppValue(SPBPLExtensionLicense, 'installDate'));
            Evaluate(IsoNumber, SPBPLIsoStoreManager.GetAppValue(SPBPLExtensionLicense, 'preactivationDays'));
            if IsoNumber > 0 then
                GraceEndDate := CalcDate(StrSubstNo(DaysGraceTok, IsoNumber), DT2Date(InstallDateTime))
            else
                if (EnvironmentInformation.IsSandbox() and (IsoNumber < 0)) then
                    // -1 days grace for a Sandbox means it's unlimited use in sandboxes, even if not activated.
                    exit(true)
                else
                    GraceEndDate := Today;
            if (GraceEndDate = Today) and GuiAllowed then
                Message(GraceExpiringMsg, SPBPLExtensionLicense."Extension Name");
            if GraceEndDate > Today then
                exit(true);
        end;

        Evaluate(LastCheckDateTime, SPBPLIsoStoreManager.GetAppValue(SPBPLExtensionLicense, 'lastCheckDate'));
        if ((Today() - DT2Date(LastCheckDateTime)) > 0) then begin
            if LicensePlatform.CallAPIForVerification(SPBPLExtensionLicense, ResponseBody, false) then begin
                // This may update the End Dates - note: may or may not call .Modify
                LicensePlatform.PopulateSubscriptionFromResponse(SPBPLExtensionLicense, ResponseBody);
                SPBPLExtensionLicense.Modify();
            end;
            DoVersionCheck(SPBPLExtensionLicense);
            SPBPLIsoStoreManager.SetAppValue(SPBPLExtensionLicense, 'lastCheckDate', Format(CurrentDateTime, 0, 9));
        end;

        // if the subscription ran out
        if (SPBPLExtensionLicense."Subscription End Date" < CurrentDateTime) and
          (SPBPLExtensionLicense."Subscription End Date" <> 0DT)
        then
            exit(false);


        // if the record version IS active, then let's crosscheck against isolated storage
        Evaluate(IsoActive, SPBPLIsoStoreManager.GetAppValue(SPBPLExtensionLicense, 'active'));
        if not IsoActive then
            LicensePlatform.ReportPossibleMisuse(SPBPLExtensionLicense);

        // Check Record end date against IsoStorage end date
        Evaluate(IsoDatetime, SPBPLIsoStoreManager.GetAppValue(SPBPLExtensionLicense, 'endDate'));
        if IsoDatetime <> 0DT then
            // Only checking at the date level in case of time zone nonsense
            if DT2Date(IsoDatetime) <> DT2Date(SPBPLExtensionLicense."Subscription End Date") then
                LicensePlatform.ReportPossibleMisuse(SPBPLExtensionLicense);

        // Finally, all things checked out
        exit(true);
    end;

    local procedure ActivateExtension(var SPBPLExtensionLicense: Record "SPBPL Extension License"; ResponseBody: Text): Boolean
    var
        LicensePlatform: Interface "SPBPL ILicenseCommunicator";
        AppInfo: ModuleInfo;
        ActivationFailureErr: Label 'An error occured validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
        LicenseKeyExpiredErr: Label 'The License Key provided has already expired due to a Subscription End.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
    begin
        NavApp.GetModuleInfo(SPBPLExtensionLicense."Entry Id", AppInfo);

        // Note we're swapping the ResponseBody to the 2nd API call with the new info from the API!
        LicensePlatform := SPBPLExtensionLicense."License Platform";
        if LicensePlatform.CallAPIForVerification(SPBPLExtensionLicense, ResponseBody, true) then begin

            LicensePlatform.PopulateSubscriptionFromResponse(SPBPLExtensionLicense, ResponseBody);

            if (SPBPLExtensionLicense."Subscription End Date" <> 0DT) and
              (SPBPLExtensionLicense."Subscription End Date" < CurrentDateTime)
            then begin
                SPBPLExtensionLicense.Activated := false;
                SPBPLExtensionLicense.Modify();
                Commit();
                OnAfterActivationFailure(SPBPLExtensionLicense, AppInfo);
                if GuiAllowed() then
                    Error(LicenseKeyExpiredErr, AppInfo.Publisher);
            end else begin
                SPBPLExtensionLicense.Modify();
                Commit();
                OnAfterActivationSuccess(SPBPLExtensionLicense, AppInfo);
            end;

            // Now pop the details into IsolatedStorage
            SPBPLLicenseUtilities.UpdateOrCreateIsoStorage(SPBPLExtensionLicense, ResponseBody);
            exit(SPBPLExtensionLicense.Activated);
        end else
            if GuiAllowed() then
                Error(ActivationFailureErr, AppInfo.Publisher);
    end;

    internal procedure DoVersionCheck(var SPBPLExtensionLicense: Record "SPBPL Extension License")
    var
        UserTask: Record "User Task";
        SubjectTok: Label 'Update Extension: %1', Comment = '%1 is Extension Name';
        DocsTok: Label 'https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/tenant-admin-center-manage-apps#get-an-overview-and-check-for-updates';
        ApiHttpClient: HttpClient;
        ApiHttpRequestMessage: HttpRequestMessage;
        ApiHttpResponseMessage: HttpResponseMessage;
        VersionResponseBody: Text;
        IsHandled: Boolean;
        LatestVersion: Version;
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if SPBPLExtensionLicense."Version Check URL" = '' then
            exit;

        ApiHttpRequestMessage.SetRequestUri(SPBPLExtensionLicense."Version Check URL");
        ApiHttpRequestMessage.Method('GET');

        if ApiHttpClient.Send(ApiHttpRequestMessage, ApiHttpResponseMessage) then begin
            if ApiHttpResponseMessage.IsSuccessStatusCode then begin
                ApiHttpResponseMessage.Content.ReadAs(VersionResponseBody);
                LatestVersion := Version.Create(VersionResponseBody);
                if (AppInfo.AppVersion < LatestVersion) then begin
                    SPBPLExtensionLicense."Update Available" := true;
                    SPBPLExtensionLicense.Modify();

                    OnBeforeVersionCheckUpgradeAvailable(SPBPLExtensionLicense, LatestVersion, IsHandled);
                    if IsHandled then
                        exit;

                    UserTask.Init();
                    UserTask.Title := StrSubstNo(SubjectTok, AppInfo.Name);
                    UserTask.SetDescription(DocsTok);
                    if not IsNullGuid(SPBPLExtensionLicense."Activated By") then
                        UserTask."Assigned To" := SPBPLExtensionLicense."Activated By";
                    UserTask."Due DateTime" := CurrentDateTime;
                    UserTask."Start DateTime" := CurrentDateTime;
                    UserTask."Object Type" := UserTask."Object Type"::Page;
                    UserTask."Object ID" := Page::"SPBPL Extension Licenses";
                    UserTask.Insert(true);
                end;
            end else
                OnAfterVersionCheckFailure(SPBPLExtensionLicense, ApiHttpResponseMessage);
        end else
            OnAfterVersionCheckFailure(SPBPLExtensionLicense, ApiHttpResponseMessage);
    end;

    internal procedure DeactivateExtension(var SPBPLExtensionLicense: Record "SPBPL Extension License"): Boolean
    var
        DeactivationWarningQst: Label 'This will deactivate this license in this Business Central instance, but you will need to contact the Publisher to release the assigned license. \ \Are you sure you want to deactivate this license?';
    begin
        if Confirm(DeactivationWarningQst, false) then begin
            SPBPLExtensionLicense.Validate(Activated, false);
            SPBPLExtensionLicense.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterActivationFailure(var SPBPLExtensionLicense: Record "SPBPL Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVersionCheckUpgradeAvailable(var SPBPLExtensionLicense: Record "SPBPL Extension License"; var LatestVersion: Version; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterActivationSuccess(var SPBPLExtensionLicense: Record "SPBPL Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVersionCheckFailure(var SPBPLExtensionLicense: Record "SPBPL Extension License"; var ApiHttpResponseMessage: HttpResponseMessage)
    begin
    end;

}
