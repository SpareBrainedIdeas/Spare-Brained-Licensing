codeunit 71264330 "CAVSB Version Check"
{
    Access = Internal;

    procedure DoVersionCheck(var CAVExtensionLicense: Record "CAVSB Extension License")
    var
        UserTask: Record "User Task";
        CAVSBEvents: Codeunit "CAVSB Events";
        CAVSBTelemetry: Codeunit "CAVSB Telemetry";
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
        if CAVExtensionLicense."Version Check URL" = '' then
            exit;

        ApiHttpRequestMessage.SetRequestUri(CAVExtensionLicense."Version Check URL");
        ApiHttpRequestMessage.Method('GET');

        if ApiHttpClient.Send(ApiHttpRequestMessage, ApiHttpResponseMessage) then begin
            if ApiHttpResponseMessage.IsSuccessStatusCode then begin
                ApiHttpResponseMessage.Content.ReadAs(VersionResponseBody);
                LatestVersion := Version.Create(VersionResponseBody);
                if (AppInfo.AppVersion < LatestVersion) then begin
                    CAVExtensionLicense."Update Available" := true;
                    CAVExtensionLicense.Modify();

                    CAVSBEvents.OnBeforeVersionCheckUpgradeAvailable(CAVExtensionLicense, LatestVersion, IsHandled);
                    if IsHandled then
                        exit;

                    UserTask.Init();
                    UserTask.Title := StrSubstNo(SubjectTok, AppInfo.Name);
                    UserTask.SetDescription(DocsTok);
                    if not IsNullGuid(CAVExtensionLicense."Activated By") then
                        UserTask."Assigned To" := CAVExtensionLicense."Activated By";
                    UserTask."Due DateTime" := CurrentDateTime;
                    UserTask."Start DateTime" := CurrentDateTime;
                    UserTask."Object Type" := UserTask."Object Type"::Page;
                    UserTask."Object ID" := Page::"CAVSB Extension Licenses";
                    UserTask.Insert(true);
                end;
            end else
                CAVSBEvents.OnAfterVersionCheckFailure(CAVExtensionLicense, ApiHttpResponseMessage);
        end else
            CAVSBEvents.OnAfterVersionCheckFailure(CAVExtensionLicense, ApiHttpResponseMessage);
        CAVSBTelemetry.VersionUpdateCheck(CAVExtensionLicense);
    end;
}
