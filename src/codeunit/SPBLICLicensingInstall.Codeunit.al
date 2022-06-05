codeunit 71037 "SPBPL Licensing Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        SPBExtensionLicense: Record "SPBPL Extension License";
        SPBPLLicenseUtilities: Codeunit "SPBPL License Utilities";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        // We install / update the 'Test' entry
        if not SPBExtensionLicense.Get(AppInfo.Id) then begin
            SPBExtensionLicense.Init();
            Evaluate(SPBExtensionLicense."Entry Id", AppInfo.Id);
            SPBExtensionLicense.Insert(true);
        end;
        SPBExtensionLicense."Extension Name" := AppInfo.Name + ' Test Subcription';
        SPBExtensionLicense."Product Code" := CopyStr(SPBPLLicenseUtilities.GetTestProductId(), 1, MaxStrLen(SPBExtensionLicense."Product Code"));
        SPBExtensionLicense."Product URL" := 'https://sparebrained.gumroad.com/l/SBILicensingTest';
        SPBExtensionLicense."Support URL" := 'support@sparebrained.com';
        SPBExtensionLicense."Billing Support Email" := 'support@sparebrained.com';
        SPBExtensionLicense.Modify();
    end;
}
