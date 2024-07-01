codeunit 71033580 "SPBLIC IsoStore Manager"
{
    Permissions = tabledata "SPBLIC IsoStore Map" = RMID;
    // Utility Codeunit
    var
        SPBLICIsoStoreMap: Record "SPBLIC IsoStore Map";
        CryptographyManagement: Codeunit "Cryptography Management";
        EnvironmentInformation: Codeunit "Environment Information";
        NameMapTok: Label '%1-%2', Comment = '%1 %2', Locked = true;

    internal procedure UpdateOrCreateIsoStorage(var SPBExtensionLicense: Record "SPBLIC Extension License")
    var
        YesterdayDateTime: DateTime;
    begin
        SetAppValue(SPBExtensionLicense, 'lastUpdated', Format(CurrentDateTime, 0, 9));
        SetAppValue(SPBExtensionLicense, 'endDate', Format(SPBExtensionLicense."Subscription End Date", 0, 9));
        SetAppValue(SPBExtensionLicense, 'active', Format(SPBExtensionLicense.IsActive(), 0, 9));
        SetAppValue(SPBExtensionLicense, 'preactivationDays', Format(SPBExtensionLicense."Sandbox Grace Days", 0, 9));

        // We mark the lastCheckDate as yesterday on activation to trigger one check DURING activation, just to be safe
        // Someone could be installing from an app file that's outdated, etc.
        YesterdayDateTime := CreateDateTime(CalcDate('<-1D>', Today()), Time());
        SetAppValue(SPBExtensionLicense, 'lastCheckDate', Format(YesterdayDateTime, 0, 9));

        if not ContainsAppValue(SPBExtensionLicense, 'extensionContactEmail') then begin
            SetAppValue(SPBExtensionLicense, 'extensionContactEmail', SPBExtensionLicense."Billing Support Email");
            SetAppValue(SPBExtensionLicense, 'extensionMisuseURI', '');
        end;
    end;

    internal procedure SetAppValue(SPBExtensionLicense: Record "SPBLIC Extension License"; StoreName: Text; StoreValue: Text)
    var
        ComposedKeyName: Text;
    begin
        if not IsolatedStorage.Contains(SPBExtensionLicense."Entry Id") then
            IsolatedStorage.Set(SPBExtensionLicense."Entry Id", '', DataScope::Module);

        if not SPBLICIsoStoreMap.Get(SPBExtensionLicense."Entry Id") then begin
            SPBLICIsoStoreMap.Init();
            SPBLICIsoStoreMap."Origin Entry Id" := SPBExtensionLicense."Entry Id";
            SPBLICIsoStoreMap.IsoKey := Format(SPBExtensionLicense."Entry Id");
            SPBLICIsoStoreMap.Insert();
        end;

        if not EnvironmentInformation.IsSaaS() then
            if CryptographyManagement.IsEncryptionEnabled() and CryptographyManagement.IsEncryptionPossible() then
                StoreValue := CryptographyManagement.EncryptText(CopyStr(StoreValue, 1, 215))
            else
                Error('To use Spare Brained Licensing On-Prem, Database Encryption must be enabled.');

        ComposedKeyName := ComposeKeyName(SPBExtensionLicense."Entry Id", StoreName);
        IsolatedStorage.Set(ComposedKeyName, StoreValue, DataScope::Module);
        if not SPBLICIsoStoreMap.Get(SPBExtensionLicense."Entry Id") then begin
            SPBLICIsoStoreMap.Init();
            SPBLICIsoStoreMap."Origin Entry Id" := SPBExtensionLicense."Entry Id";
            SPBLICIsoStoreMap.IsoKey := Format(SPBExtensionLicense."Entry Id");
            SPBLICIsoStoreMap.Insert();
        end;
    end;

    internal procedure GetAppValue(SPBExtensionLicense: Record "SPBLIC Extension License"; StoreName: Text; var ReturnValue: Text) Found: Boolean
    var
        ComposedKeyName: Text;
    begin
        ComposedKeyName := ComposeKeyName(SPBExtensionLicense."Entry Id", StoreName);
        Found := IsolatedStorage.Get(ComposedKeyName, DataScope::Module, ReturnValue);
        if (not EnvironmentInformation.IsSaaS()) and CryptographyManagement.IsEncryptionEnabled() and CryptographyManagement.IsEncryptionPossible() then
            ReturnValue := CryptographyManagement.Decrypt(ReturnValue);
    end;

    internal procedure ContainsAppValue(SPBExtensionLicense: Record "SPBLIC Extension License"; StoreName: Text): Boolean
    var
        ComposedKeyName: Text;
    begin
        ComposedKeyName := ComposeKeyName(SPBExtensionLicense."Entry Id", StoreName);
        exit(IsolatedStorage.Contains(ComposedKeyName, DataScope::Module));
    end;

    internal procedure RemoveAppValue(SPBExtensionLicense: Record "SPBLIC Extension License"; StoreName: Text)
    var
        ComposedKeyName: Text;
    begin
        ComposedKeyName := ComposeKeyName(SPBExtensionLicense."Entry Id", StoreName);
        IsolatedStorage.Delete(ComposedKeyName, DataScope::Module);
    end;

    local procedure ComposeKeyName(EntryId: Guid; StoreName: Text): Text
    begin
        exit(StrSubstNo(NameMapTok, EntryId, StoreName));
    end;
}
