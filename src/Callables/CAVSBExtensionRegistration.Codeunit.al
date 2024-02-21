/// <summary>
/// This codeunit is for properly registering Extensions into the Licensing system. 
/// </summary>
codeunit 71034 "CAVSB Extension Registration"
{
    Permissions = tabledata "CAVSB Extension License" = RIM;

    /// <summary>
    /// This function with an appalling number of parameters allows Extensions to register as License.
    /// </summary>
    /// <param name="AppInfo">The ModuleInfo of the Extension</param>
    /// <param name="newProductCode">The unique Product Code relevant for the Licensing Platform.</param>
    /// <param name="newProductUrl">The unique Product URL for the Licensing Platform.</param>
    /// <param name="newSupportUrl">A URL for users looking for support info. This should be a page on your site with product information.</param>
    /// <param name="newBillingEmail">An email to contact about any invoicing/payment questions.</param>
    /// <param name="newVersionURL">An optional URL to check for a version string (x.x.x.x).</param>
    /// <param name="newUpdateNewsURL">An optional URL to check for update news information.</param>
    /// <param name="daysAllowedBeforeActivationProd">In an On-Premises or Cloud Production environment, how many days may an extension work before requiring activation.</param>
    /// <param name="daysAllowedBeforeActivationSandbox">In a Cloud Sandbox environment, how many days may an extension work before requiring activation.</param>
    /// <param name="minimumLicensingAppVersion">Since the licensing app has versions too, what minimum version of the Licensing App is required</param>
    /// <param name="licensePlatform">Which platform should be used.  Out of box options are Gumroad and LemonSqueezy, though it may be extended.</param>
    /// <param name="forceUpdate">This setting forces changes over any existing record in the Licensing app to ensure new information updates are pushed in.</param>
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
        licensePlatform: Enum "CAVSB License Platform";
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

    /// <summary>
    /// This function with an appalling number of parameters allows Extensions to register as License, this one using an optional Submodule functionality, allowing licensing parts of an Extension, or more complex scenarios.
    /// </summary>
    /// <param name="AppInfo">The ModuleInfo of the Extension</param>
    /// <param name="SubModuleId">Unique GUID for the Submodule, so you can future-proof against name changes</param>
    /// <param name="SubModuleName">The Display name of the submodule</param>
    /// <param name="newProductCode">The unique Product Code relevant for the Licensing Platform.</param>
    /// <param name="newProductUrl">The unique Product URL for the Licensing Platform.</param>
    /// <param name="newSupportUrl">A URL for users looking for support info. This should be a page on your site with product information.</param>
    /// <param name="newBillingEmail">An email to contact about any invoicing/payment questions.</param>
    /// <param name="newVersionURL">An optional URL to check for a version string (x.x.x.x).</param>
    /// <param name="newUpdateNewsURL">An optional URL to check for update news information.</param>
    /// <param name="daysAllowedBeforeActivationProd">In an On-Premises or Cloud Production environment, how many days may an extension work before requiring activation.</param>
    /// <param name="daysAllowedBeforeActivationSandbox">In a Cloud Sandbox environment, how many days may an extension work before requiring activation.</param>
    /// <param name="minimumLicensingAppVersion">Since the licensing app has versions too, what minimum version of the Licensing App is required</param>
    /// <param name="licensePlatform">Which platform should be used.  Out of box options are Gumroad and LemonSqueezy, though it may be extended.</param>
    /// <param name="forceUpdate">This setting forces changes over any existing record in the Licensing app to ensure new information updates are pushed in.</param>
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
        licensePlatform: Enum "CAVSB License Platform";
        forceUpdate: Boolean)
    var
        CAVExtensionLicense: Record "CAVSB Extension License";
        EnvironmentInformation: Codeunit "Environment Information";
        CAVIsoStoreManager: Codeunit "CAVSB IsoStore Manager";
        CAVSBTelemetry: Codeunit "CAVSB Telemetry";
        GraceEndDate: Date;
        GraceDays: Integer;
        PlusDaysTok: Label '<+%1D>', Comment = '%1 is the number of days ';
    begin
        if minimumLicensingAppVersion > Version.Create('1.0.0.0') then
            CheckSupportedVersion(minimumLicensingAppVersion);

        if EnvironmentInformation.IsOnPrem() or EnvironmentInformation.IsProduction() then
            GraceDays := daysAllowedBeforeActivationProd
        else
            GraceDays := daysAllowedBeforeActivationSandbox;
        if GraceDays > 0 then
            GraceEndDate := CalcDate(StrSubstNo(PlusDaysTok, daysAllowedBeforeActivationProd), Today)
        else
            GraceEndDate := Today;

        if (CAVExtensionLicense.Get(SubModuleId)) then begin
            if forceUpdate then begin
                CAVExtensionLicense."Submodule Name" := SubModuleName;
                CAVExtensionLicense."Extension Name" := CopyStr(AppInfo.Name, 1, MaxStrLen(CAVExtensionLicense."Extension Name"));
                CAVExtensionLicense."Product Code" := newProductCode;
                CAVExtensionLicense."Product URL" := newProductUrl;
                CAVExtensionLicense."Support URL" := newSupportUrl;
                CAVExtensionLicense."Billing Support Email" := newBillingEmail;
                CAVExtensionLicense."Version Check URL" := newVersionURL;
                CAVExtensionLicense."Update News URL" := newUpdateNewsURL;
                CAVExtensionLicense."Sandbox Grace Days" := daysAllowedBeforeActivationSandbox;
                CAVExtensionLicense.Modify();
            end;
        end else begin
            CAVExtensionLicense."Entry Id" := SubModuleId;
            CAVExtensionLicense."Submodule Name" := SubModuleName;
            CAVExtensionLicense."Extension App Id" := AppInfo.Id;
            CAVExtensionLicense."Extension Name" := CopyStr(AppInfo.Name, 1, MaxStrLen(CAVExtensionLicense."Extension Name"));
            CAVExtensionLicense."Product Code" := newProductCode;
            CAVExtensionLicense."Product URL" := newProductUrl;
            CAVExtensionLicense."Support URL" := newSupportUrl;
            CAVExtensionLicense."Billing Support Email" := newBillingEmail;
            CAVExtensionLicense."Version Check URL" := newVersionURL;
            CAVExtensionLicense."Update News URL" := newUpdateNewsURL;
            CAVExtensionLicense."Installed At" := CurrentDateTime();
            CAVExtensionLicense."Trial Grace End Date" := GraceEndDate;
            CAVExtensionLicense."Sandbox Grace Days" := daysAllowedBeforeActivationSandbox;
            CAVExtensionLicense.Insert(true);
        end;
        CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'installDate', Format(CurrentDateTime, 0, 9));
        CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'preactivationDays', Format(GraceDays));
        CAVSBTelemetry.NewExtensionRegistered(CAVExtensionLicense);
    end;

    internal procedure CheckSupportedVersion(minVersion: Version)
    var
        VersionUpdateRequiredErr: Label 'To install this Extension, you need to update %1 to at least version %2.', Comment = '%1 is the name of licensing extension, %2 is the version number';
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if AppInfo.AppVersion < minVersion then
            if GuiAllowed then
                Error(VersionUpdateRequiredErr, AppInfo.Name, minVersion);
    end;

    [Obsolete('Use CAV Check Active method codeunit instead.')]
    procedure CheckIfActive(SubscriptionId: Guid; InactiveShowError: Boolean): Boolean
    begin
    end;
}
