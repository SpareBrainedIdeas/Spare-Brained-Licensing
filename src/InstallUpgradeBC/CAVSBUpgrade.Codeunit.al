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
        CAVExtensionLicense: Record "CAVSB Extension License";
    begin
        if CAVExtensionLicense.FindSet() then
            repeat
                if IsNullGuid(CAVExtensionLicense."Extension App Id") then begin
                    CAVExtensionLicense."Extension App Id" := CAVExtensionLicense."Entry Id";
                    CAVExtensionLicense.Modify(true);
                end;
            until CAVExtensionLicense.Next() = 0;
    end;

    local procedure Performv21Upgrade()
    var
        CAVExtensionLicense: Record "CAVSB Extension License";
        CAVSBensingInstall: Codeunit "CAVSB Licensing Install";
        AppInfo: ModuleInfo;
    begin
        // Removing any older Subscriptions that was just for Gumroad
        NavApp.GetCurrentModuleInfo(AppInfo);
        CAVExtensionLicense.SetRange("Extension App Id", AppInfo.Id);
        CAVExtensionLicense.DeleteAll();

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