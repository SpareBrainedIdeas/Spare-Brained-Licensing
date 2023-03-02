codeunit 71039 "SPBPL Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    var
        SPBPLTelemetry: Codeunit "SPBPL Telemetry";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(v20ReasonLbl) then begin
            Performv20Upgrade();
            UpgradeTag.SetUpgradeTag(v20ReasonLbl);
        end;
        if not UpgradeTag.HasUpgradeTag(v21ReasonLbl) then begin
            Performv21Upgrade();
            UpgradeTag.SetUpgradeTag(v21ReasonLbl);
        end;
        SPBPLTelemetry.LicensingAppUpgraded();
    end;

    local procedure Performv20Upgrade()
    var
        SPBExtensionLicense: Record "SPBPL Extension License";
    begin
        if SPBExtensionLicense.FindSet() then
            repeat
                if IsNullGuid(SPBExtensionLicense."Extension App Id") then begin
                    SPBExtensionLicense."Extension App Id" := SPBExtensionLicense."Entry Id";
                    SPBExtensionLicense.Modify(true);
                end;
            until SPBExtensionLicense.Next() = 0;
    end;

    local procedure Performv21Upgrade()
    var
        SPBExtensionLicense: Record "SPBPL Extension License";
        SPBPLensingInstall: Codeunit "SPBPL Licensing Install";
        AppInfo: ModuleInfo;
    begin
        // Removing any older Subscriptions that was just for Gumroad
        NavApp.GetCurrentModuleInfo(AppInfo);
        SPBExtensionLicense.SetRange("Extension App Id", AppInfo.Id);
        SPBExtensionLicense.DeleteAll();

        // To using the submodule system to test whatever platforms
        SPBPLensingInstall.PerformInstallOfTestSubscriptions();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure OnGetPerCompanyUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]]);
    begin
        PerDatabaseUpgradeTags.Add(v20ReasonLbl);
        PerDatabaseUpgradeTags.Add(v21ReasonLbl);
    end;


    var
        v20ReasonLbl: Label 'SBI-V20-20220430', Locked = true;
        v21ReasonLbl: Label 'SBILicensing-V21-20230212', Locked = true;
}