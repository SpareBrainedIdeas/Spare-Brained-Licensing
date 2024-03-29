codeunit 71044 "SPBPL Version Check"
{
    Access = Internal;

    procedure DoVersionCheck(var SPBExtensionLicense: Record "SPBPL Extension License")
    var
        UserTask: Record "User Task";
        SPBPLEvents: Codeunit "SPBPL Events";
        SPBPLTelemetry: Codeunit "SPBPL Telemetry";
        IsHandled: Boolean;
        ApiHttpClient: HttpClient;
        ApiHttpRequestMessage: HttpRequestMessage;
        ApiHttpResponseMessage: HttpResponseMessage;
        DocsTok: Label 'https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/tenant-admin-center-manage-apps#get-an-overview-and-check-for-updates', Locked = true;
        SubjectTok: Label 'Update Extension: %1', Comment = '%1 is Extension Name';
        AppInfo: ModuleInfo;
        VersionResponseBody: Text;
        LatestVersion: Version;
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

                    SPBPLEvents.OnBeforeVersionCheckUpgradeAvailable(SPBExtensionLicense, LatestVersion, IsHandled);
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
                SPBPLEvents.OnAfterVersionCheckFailure(SPBExtensionLicense, ApiHttpResponseMessage);
        end else
            SPBPLEvents.OnAfterVersionCheckFailure(SPBExtensionLicense, ApiHttpResponseMessage);
        SPBPLTelemetry.VersionUpdateCheck(SPBExtensionLicense);
    end;
}
