codeunit 71039 "CAVSB Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        CAVSBTelemetry: Codeunit "CAVSB Telemetry";
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
        CAVSBTelemetry.LicensingAppUpgraded();
    end;

    local procedure Performv20Upgrade()
    var
        SPBExtensionLicense: Record "CAVSB Extension License";
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
        SPBExtensionLicense: Record "CAVSB Extension License";
        CAVSBensingInstall: Codeunit "CAVSB Licensing Install";
        AppInfo: ModuleInfo;
    begin
        // Removing any older Subscriptions that was just for Gumroad
        NavApp.GetCurrentModuleInfo(AppInfo);
        SPBExtensionLicense.SetRange("Extension App Id", AppInfo.Id);
        SPBExtensionLicense.DeleteAll();

        // To using the submodule system to test whatever platforms
        CAVSBensingInstall.PerformInstallOfTestSubscriptions();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]]);
    begin
        PerCompanyUpgradeTags.Add(v20ReasonLbl);
        PerCompanyUpgradeTags.Add(v21ReasonLbl);
    end;


    var
        v20ReasonLbl: Label 'SBI-V20-20220430', Locked = true;
        v21ReasonLbl: Label 'SBILicensing-V21-20230212', Locked = true;
}