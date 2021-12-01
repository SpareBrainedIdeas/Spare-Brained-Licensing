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
    var
        SPBPLExtensionLicense: Record "SPBPL Extension License";
        SPBPLLicenseManagement: Codeunit "SPBPL License Management";
        SPBPLIsoStoreManager: Codeunit "SPBPL IsoStore Manager";
        EnvironmentInformation: Codeunit "Environment Information";
        PlusDaysTok: Label '<+%1D>', Comment = '%1 is the number of days ';
        GraceEndDate: Date;
        GraceDays: Integer;
    begin
        if minimumLicensingAppVersion > Version.Create('1.0.0.0') then
            SPBPLLicenseManagement.CheckSupportedVersion(minimumLicensingAppVersion);

        if EnvironmentInformation.IsOnPrem() or EnvironmentInformation.IsProduction() then
            GraceDays := daysAllowedBeforeActivationProd
        else
            GraceDays := daysAllowedBeforeActivationSandbox;
        if GraceDays > 0 then
            GraceEndDate := CalcDate(StrSubstNo(PlusDaysTok, daysAllowedBeforeActivationProd), Today)
        else
            GraceEndDate := Today;

        if (SPBPLExtensionLicense.Get(AppInfo.Id)) then begin
            if forceUpdate then begin
                SPBPLExtensionLicense."Extension Name" := CopyStr(AppInfo.Name, 1, MaxStrLen(SPBPLExtensionLicense."Extension Name"));
                SPBPLExtensionLicense."Product Code" := newProductCode;
                SPBPLExtensionLicense."Product URL" := newProductUrl;
                SPBPLExtensionLicense."Support URL" := newSupportUrl;
                SPBPLExtensionLicense."Billing Support Email" := newBillingEmail;
                SPBPLExtensionLicense."Version Check URL" := newVersionURL;
                SPBPLExtensionLicense."Update News URL" := newUpdateNewsURL;
                SPBPLExtensionLicense.Modify();
            end;
        end else begin
            SPBPLExtensionLicense."Entry Id" := AppInfo.Id;
            SPBPLExtensionLicense."Extension Name" := CopyStr(AppInfo.Name, 1, MaxStrLen(SPBPLExtensionLicense."Extension Name"));
            SPBPLExtensionLicense."Product Code" := newProductCode;
            SPBPLExtensionLicense."Product URL" := newProductUrl;
            SPBPLExtensionLicense."Support URL" := newSupportUrl;
            SPBPLExtensionLicense."Billing Support Email" := newBillingEmail;
            SPBPLExtensionLicense."Version Check URL" := newVersionURL;
            SPBPLExtensionLicense."Update News URL" := newUpdateNewsURL;
            SPBPLExtensionLicense."Installed At" := CurrentDateTime();
            SPBPLExtensionLicense."Trial Grace End Date" := GraceEndDate;
            SPBPLExtensionLicense.Insert();
        end;
        SPBPLIsoStoreManager.SetAppValue(SPBPLExtensionLicense, 'installDate', Format(CurrentDateTime, 0, 9));
        SPBPLIsoStoreManager.SetAppValue(SPBPLExtensionLicense, 'preactivationDays', Format(GraceDays));
    end;

    procedure CheckIfActive(AppId: Guid; InactiveShowError: Boolean): Boolean
    var
        SPBPLExtensionLicense: Record "SPBPL Extension License";
        SPBPLLicenseManagement: Codeunit "SPBPL License Management";
        NoSubFoundErr: Label 'No Subscription was found in the Subscriptions list for AppId: %1', Comment = '%1 is which Application ID';
        SubscriptionInactiveErr: Label 'The Subscription for %1 is not Active.  Contact your system administrator to re-activate it.', Comment = '%1 is the name of the Subscription';
        IsActive: Boolean;
    begin
        if not SPBPLExtensionLicense.get(AppId) then
            if GuiAllowed() then
                Error(NoSubFoundErr, AppId);
        IsActive := SPBPLLicenseManagement.CheckIfActive(SPBPLExtensionLicense);
        if not IsActive and InactiveShowError then
            if GuiAllowed() then
                Error(SubscriptionInactiveErr, SPBPLExtensionLicense."Extension Name");
        exit(IsActive);
    end;
}
