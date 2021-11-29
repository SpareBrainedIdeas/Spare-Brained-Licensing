codeunit 71033 "SPBPL License Utilities"
{

    var
        SelfTestProductIdTok: Label 'bwdCu';
        SelfTestProductKeyTok: Label '21E2339D-F24D4A92-9813B4F2-8ABA083C';

    internal procedure GetTestProductAppId(): Guid
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.Id);
    end;

    internal procedure GetTestProductId(): Text
    begin
        exit(SelfTestProductIdTok);
    end;

    internal procedure GetTestProductKey(): Text
    begin
        exit(SelfTestProductKeyTok);
    end;

    internal procedure LaunchProductUrl(SPBPLExtensionLicense: Record "SPBPL Extension License")
    var
        IsHandled: Boolean;
    begin
        OnBeforeLaunchProductUrl(SPBPLExtensionLicense, IsHandled);
        if not IsHandled then
            Hyperlink(SPBPLExtensionLicense."Product URL");
    end;

    internal procedure AddNameValuePair(var FormData: TextBuilder; name: Text; value: Text)
    var
        FormDataNameTok: Label 'Content-Disposition: form-data; name="%1"', Comment = '%1 is the name of the Form Data';
    begin
        FormData.AppendLine('--SpareBrainedLicensing');
        FormData.AppendLine(StrSubstNo(FormDataNameTok, name));
        FormData.AppendLine();
        FormData.AppendLine(value);
        FormData.AppendLine('--SpareBrainedLicensing--');
    end;

    internal procedure UpdateOrCreateIsoStorage(var SPBPLExtensionLicense: Record "SPBPL Extension License"; ApiResponse: Text)
    var
        SPBPLIsoStoreManager: Codeunit "SPBPL IsoStore Manager";
        YesterdayDateTime: DateTime;
    begin
        SPBPLIsoStoreManager.SetAppValue(SPBPLExtensionLicense, 'lastUpdated', Format(CurrentDateTime, 0, 9));
        SPBPLIsoStoreManager.SetAppValue(SPBPLExtensionLicense, 'endDate', Format(SPBPLExtensionLicense."Subscription End Date", 0, 9));
        SPBPLIsoStoreManager.SetAppValue(SPBPLExtensionLicense, 'active', Format(SPBPLExtensionLicense.Activated));

        // We mark the lastCheckDate as yesterday on activation to trigger one check DURING activation, just to be safe
        // Someone could be installing from an app file that's outdated, etc.
        YesterdayDateTime := CreateDateTime(CalcDate('<-1D>', Today()), Time());
        SPBPLIsoStoreManager.SetAppValue(SPBPLExtensionLicense, 'lastCheckDate', Format(YesterdayDateTime, 0, 9));

        if not SPBPLIsoStoreManager.ContainsAppValue(SPBPLExtensionLicense, 'extensionContactEmail') then begin
            SPBPLIsoStoreManager.SetAppValue(SPBPLExtensionLicense, 'extensionContactEmail', SPBPLExtensionLicense."Billing Support Email");
            SPBPLIsoStoreManager.SetAppValue(SPBPLExtensionLicense, 'extensionMisuseURI', '');
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLaunchProductUrl(var SPBPLExtensionLicense: Record "SPBPL Extension License"; var IsHandled: Boolean)
    begin
    end;
}
