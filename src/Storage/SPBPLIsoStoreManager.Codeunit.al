codeunit 71038 "SPBPL IsoStore Manager"
{
    // Utility Codeunit
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        EnvironmentInformation: Codeunit "Environment Information";
        NameMapTok: Label '%1-%2', Comment = '%1 %2', Locked = true;

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

    internal procedure SetAppValue(SPBExtensionLicense: Record "SPBPL Extension License"; StoreName: Text; StoreValue: Text)
    begin
        if not IsolatedStorage.Contains(SPBExtensionLicense."Entry Id") then
            IsolatedStorage.Set(SPBExtensionLicense."Entry Id", '', DataScope::Module);

        if EnvironmentInformation.IsOnPrem() then
            if CryptographyManagement.IsEncryptionEnabled() and CryptographyManagement.IsEncryptionPossible() then
                StoreValue := CryptographyManagement.EncryptText(CopyStr(StoreValue, 1, 215))
            else
                if GuiAllowed() then
                    Error('To use Spare Brained Licensing On-Prem, Database Encryption must be enabled.');

        IsolatedStorage.Set(StrSubstNo(NameMapTok, SPBExtensionLicense."Entry Id", StoreName), StoreValue, DataScope::Module);
    end;

    internal procedure GetAppValue(SPBExtensionLicense: Record "SPBPL Extension License"; StoreName: Text) ReturnValue: Text
    begin
        IsolatedStorage.Get(StrSubstNo(NameMapTok, SPBExtensionLicense."Entry Id", StoreName), DataScope::Module, ReturnValue);
        if EnvironmentInformation.IsOnPrem() and CryptographyManagement.IsEncryptionEnabled() and CryptographyManagement.IsEncryptionPossible() then
            ReturnValue := CryptographyManagement.Decrypt(ReturnValue);
    end;

    internal procedure ContainsAppValue(SPBExtensionLicense: Record "SPBPL Extension License"; StoreName: Text): Boolean
    begin
        exit(IsolatedStorage.Contains(StrSubstNo(NameMapTok, SPBExtensionLicense."Entry Id", StoreName), DataScope::Module));
    end;
}
