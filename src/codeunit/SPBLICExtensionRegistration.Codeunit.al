codeunit 71034 "SPBPL Extension Registration"
{
    Permissions = tabledata "SPBPL Extension License" = RIM;
    procedure RegisterExtension(
        AppInfo: ModuleInfo;
        newProductCode: Text[100];
        newProductUrl: Text[250];
        newSupportUrl: Text[250];
        newBillingEmail: Text[250];
        newVersionURL: Text[250];
        newUpdateNewsURL: Text[250];
        daysAllowedBeforeActivationProd: Integer;
        daysAllowedBeforeActivationSandbox: Integer;
        minimumLicensingAppVersion: Version;
        licensePlatform: Enum "SPBPL License Platform";
        forceUpdate: Boolean)
    begin
        RegisterExtension(AppInfo,
        AppInfo.Id,
        '',
        newProductCode,
        newProductUrl,
        newSupportUrl,
        newBillingEmail,
        newVersionURL,
        newUpdateNewsURL,
        daysAllowedBeforeActivationProd,
        daysAllowedBeforeActivationSandbox,
        minimumLicensingAppVersion,
        licensePlatform,
        forceUpdate);
    end;

    procedure RegisterExtension(
        AppInfo: ModuleInfo;
        SubModuleId: Guid;
        SubModuleName: Text[100];
        newProductCode: Text[100];
        newProductUrl: Text[250];
        newSupportUrl: Text[250];
        newBillingEmail: Text[250];
        newVersionURL: Text[250];
        newUpdateNewsURL: Text[250];
        daysAllowedBeforeActivationProd: Integer;
        daysAllowedBeforeActivationSandbox: Integer;
        minimumLicensingAppVersion: Version;
        licensePlatform: Enum "SPBPL License Platform";
        forceUpdate: Boolean)
    var
        SPBExtensionLicense: Record "SPBPL Extension License";
        SPBLicenseManagement: Codeunit "SPBPL License Management";
        SPBIsoStoreManager: Codeunit "SPBPL IsoStore Manager";
        EnvironmentInformation: Codeunit "Environment Information";
        PlusDaysTok: Label '<+%1D>', Comment = '%1 is the number of days ';
        GraceEndDate: Date;
        GraceDays: Integer;
    begin
        if minimumLicensingAppVersion > Version.Create('1.0.0.0') then
            SPBLicenseManagement.CheckSupportedVersion(minimumLicensingAppVersion);

        if EnvironmentInformation.IsOnPrem() or EnvironmentInformation.IsProduction() then
            GraceDays := daysAllowedBeforeActivationProd
        else
            GraceDays := daysAllowedBeforeActivationSandbox;
        if GraceDays > 0 then
            GraceEndDate := CalcDate(StrSubstNo(PlusDaysTok, daysAllowedBeforeActivationProd), Today)
        else
            GraceEndDate := Today;

        if (SPBExtensionLicense.Get(SubModuleId)) then begin
            if forceUpdate then begin
                SPBExtensionLicense."Submodule Name" := SubModuleName;
                SPBExtensionLicense."Extension Name" := CopyStr(AppInfo.Name, 1, MaxStrLen(SPBExtensionLicense."Extension Name"));
                SPBExtensionLicense."Product Code" := newProductCode;
                SPBExtensionLicense."Product URL" := newProductUrl;
                SPBExtensionLicense."Support URL" := newSupportUrl;
                SPBExtensionLicense."Billing Support Email" := newBillingEmail;
                SPBExtensionLicense."Version Check URL" := newVersionURL;
                SPBExtensionLicense."Update News URL" := newUpdateNewsURL;
                SPBExtensionLicense."Sandbox Grace Days" := daysAllowedBeforeActivationSandbox;
                SPBExtensionLicense.Modify();
            end;
        end else begin

            SPBExtensionLicense."Entry Id" := SubModuleId;
            SPBExtensionLicense."Submodule Name" := SubModuleName;
            SPBExtensionLicense."Extension App Id" := AppInfo.Id;
            SPBExtensionLicense."Extension Name" := CopyStr(AppInfo.Name, 1, MaxStrLen(SPBExtensionLicense."Extension Name"));
            SPBExtensionLicense."Product Code" := newProductCode;
            SPBExtensionLicense."Product URL" := newProductUrl;
            SPBExtensionLicense."Support URL" := newSupportUrl;
            SPBExtensionLicense."Billing Support Email" := newBillingEmail;
            SPBExtensionLicense."Version Check URL" := newVersionURL;
            SPBExtensionLicense."Update News URL" := newUpdateNewsURL;
            SPBExtensionLicense."Installed At" := CurrentDateTime();
            SPBExtensionLicense."Trial Grace End Date" := GraceEndDate;
            SPBExtensionLicense."Sandbox Grace Days" := daysAllowedBeforeActivationSandbox;
            SPBExtensionLicense.Insert();
        end;
        SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'installDate', Format(CurrentDateTime, 0, 9));
        SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'preactivationDays', Format(GraceDays));
    end;

    procedure CheckIfActive(SubscriptionId: Guid; InactiveShowError: Boolean): Boolean
    var
        SPBExtensionLicense: Record "SPBPL Extension License";
        SPBLicenseManagement: Codeunit "SPBPL License Management";
        NoSubFoundErr: Label 'No License was found in the Licenses list for SubscriptionId: %1';
        SubscriptionInactiveErr: Label 'The License for %1 is not Active.  Contact your system administrator to re-activate it.', Comment = '%1 is the name of the Extension.';
        IsActive: Boolean;
    begin
        if not SPBExtensionLicense.get(SubscriptionId) then
            if GuiAllowed() then
                Error(NoSubFoundErr, SubscriptionId);
        IsActive := SPBLicenseManagement.CheckIfActive(SPBExtensionLicense);
        if not IsActive and InactiveShowError then
            if GuiAllowed() then
                Error(SubscriptionInactiveErr, SPBExtensionLicense."Extension Name");
        exit(IsActive);
    end;
}
