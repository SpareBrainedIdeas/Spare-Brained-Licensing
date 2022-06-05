codeunit 71033 "SPBPL License Utilities"
{

    var
        SelfTestProductIdTok: Label 'bwdCu', Locked = true;
        SelfTestProductKeyTok: Label '21E2339D-F24D4A92-9813B4F2-8ABA083C', Locked = true;

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

    internal procedure LaunchProductUrl(SPBExtensionLicense: Record "SPBPL Extension License")
    var
        IsHandled: Boolean;
    begin
        OnBeforeLaunchProductUrl(SPBExtensionLicense, IsHandled);
        if not IsHandled then
            Hyperlink(SPBExtensionLicense."Product URL");
    end;

    internal procedure AddNameValuePair(var FormData: TextBuilder; name: Text; value: Text)
    var
        FormDataNameTok: Label 'Content-Disposition: form-data; name="%1"', Comment = '%1 is the name of the Form Data', Locked = true;
    begin
        FormData.AppendLine('--SpareBrainedLicensing');
        FormData.AppendLine(StrSubstNo(FormDataNameTok, name));
        FormData.AppendLine();
        FormData.AppendLine(value);
        FormData.AppendLine('--SpareBrainedLicensing--');
    end;

    internal procedure UpdateOrCreateIsoStorage(var SPBExtensionLicense: Record "SPBPL Extension License")
    var
        SPBIsoStoreManager: Codeunit "SPBPL IsoStore Manager";
        YesterdayDateTime: DateTime;
    begin
        SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'lastUpdated', Format(CurrentDateTime, 0, 9));
        SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'endDate', Format(SPBExtensionLicense."Subscription End Date", 0, 9));
        SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'active', Format(SPBExtensionLicense.Activated, 0, 9));
        SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'preactivationDays', Format(SPBExtensionLicense."Sandbox Grace Days", 0, 9));

        // We mark the lastCheckDate as yesterday on activation to trigger one check DURING activation, just to be safe
        // Someone could be installing from an app file that's outdated, etc.
        YesterdayDateTime := CreateDateTime(CalcDate('<-1D>', Today()), Time());
        SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'lastCheckDate', Format(YesterdayDateTime, 0, 9));

        if not SPBIsoStoreManager.ContainsAppValue(SPBExtensionLicense, 'extensionContactEmail') then begin
            SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'extensionContactEmail', SPBExtensionLicense."Billing Support Email");
            SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'extensionMisuseURI', '');
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLaunchProductUrl(var SPBExtensionLicense: Record "SPBPL Extension License"; var IsHandled: Boolean)
    begin
    end;
}
