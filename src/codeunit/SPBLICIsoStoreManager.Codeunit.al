codeunit 71038 "SPBPL IsoStore Manager"
{
    // Utility Codeunit
    var
        EnvironmentInformation: Codeunit "Environment Information";
        CryptographyManagement: Codeunit "Cryptography Management";
        NameMapTok: Label '%1-%2', Comment = '%1 %2', Locked = true;

    internal procedure SetAppValue(SPBExtensionLicense: Record "SPBPL Extension License"; StoreName: Text; StoreValue: Text)
    begin
        if not IsolatedStorage.Contains(SPBExtensionLicense."Entry Id") then
            IsolatedStorage.Set(SPBExtensionLicense."Entry Id", '', DataScope::Module);

        if EnvironmentInformation.IsOnPrem() then
            if CryptographyManagement.IsEncryptionEnabled() and CryptographyManagement.IsEncryptionPossible() then
                StoreValue := CryptographyManagement.Encrypt(StoreValue)
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
