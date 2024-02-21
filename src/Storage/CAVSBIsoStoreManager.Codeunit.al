codeunit 71264337 "CAVSB IsoStore Manager"
{
    // Utility Codeunit
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        EnvironmentInformation: Codeunit "Environment Information";
        NameMapTok: Label '%1-%2', Comment = '%1 %2', Locked = true;

    internal procedure UpdateOrCreateIsoStorage(var CAVExtensionLicense: Record "CAVSB Extension License")
    var
        CAVIsoStoreManager: Codeunit "CAVSB IsoStore Manager";
        YesterdayDateTime: DateTime;
    begin
        CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'lastUpdated', Format(CurrentDateTime, 0, 9));
        CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'endDate', Format(CAVExtensionLicense."Subscription End Date", 0, 9));
        CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'active', Format(CAVExtensionLicense.Activated, 0, 9));
        CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'preactivationDays', Format(CAVExtensionLicense."Sandbox Grace Days", 0, 9));

        // We mark the lastCheckDate as yesterday on activation to trigger one check DURING activation, just to be safe
        // Someone could be installing from an app file that's outdated, etc.
        YesterdayDateTime := CreateDateTime(CalcDate('<-1D>', Today()), Time());
        CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'lastCheckDate', Format(YesterdayDateTime, 0, 9));

        if not CAVIsoStoreManager.ContainsAppValue(CAVExtensionLicense, 'extensionContactEmail') then begin
            CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'extensionContactEmail', CAVExtensionLicense."Billing Support Email");
            CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'extensionMisuseURI', '');
        end;
    end;

    internal procedure SetAppValue(CAVExtensionLicense: Record "CAVSB Extension License"; StoreName: Text; StoreValue: Text)
    begin
        if not IsolatedStorage.Contains(CAVExtensionLicense."Entry Id") then
            IsolatedStorage.Set(CAVExtensionLicense."Entry Id", '', DataScope::Module);

        if EnvironmentInformation.IsOnPrem() then
            if CryptographyManagement.IsEncryptionEnabled() and CryptographyManagement.IsEncryptionPossible() then
                StoreValue := CryptographyManagement.EncryptText(CopyStr(StoreValue, 1, 215))
            else
                if GuiAllowed() then
                    Error('To use Spare Brained Licensing On-Prem, Database Encryption must be enabled.');

        IsolatedStorage.Set(StrSubstNo(NameMapTok, CAVExtensionLicense."Entry Id", StoreName), StoreValue, DataScope::Module);
    end;

    internal procedure GetAppValue(CAVExtensionLicense: Record "CAVSB Extension License"; StoreName: Text; var ReturnValue: Text) Found: Boolean
    begin
        Found := IsolatedStorage.Get(StrSubstNo(NameMapTok, CAVExtensionLicense."Entry Id", StoreName), DataScope::Module, ReturnValue);
        if EnvironmentInformation.IsOnPrem() and CryptographyManagement.IsEncryptionEnabled() and CryptographyManagement.IsEncryptionPossible() then
            ReturnValue := CryptographyManagement.Decrypt(ReturnValue);
    end;

    internal procedure ContainsAppValue(CAVExtensionLicense: Record "CAVSB Extension License"; StoreName: Text): Boolean
    begin
        exit(IsolatedStorage.Contains(StrSubstNo(NameMapTok, CAVExtensionLicense."Entry Id", StoreName), DataScope::Module));
    end;
}
