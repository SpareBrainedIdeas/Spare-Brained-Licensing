codeunit 71048 "CAVSB Telemetry"
{
    Access = Internal;

    // Events to send:
    // Self-Install / Update FYI
    // New Extension Registered
    // License activations / deactivation / platformDeactivation
    // License check:  Success/Fail
    // Misuse report
    // Version update check

    var
        EventTagInstallMsg: Label 'Installation', Locked = true;
        EventTagInstallTok: Label 'CAVSB1000', Locked = true;
        EventTagUpgradeMsg: Label 'Upgraded', Locked = true;
        EventTagUpgradeTok: Label 'CAVSB1001', Locked = true;
        EventTagNewExtensionMsg: Label 'New Extension License Registered', Locked = true;
        EventTagNewExtensionTok: Label 'CAVSB1002', Locked = true;
        EventTagLicenseActivationMsg: Label 'License Activated', Locked = true;
        EventTagLicenseActivationTok: Label 'CAVSB1100', Locked = true;
        EventTagLicenseDeactivationMsg: Label 'License Deactivated', Locked = true;
        EventTagLicenseDeactivationTok: Label 'CAVSB1101', Locked = true;
        EventTagLicensePlatformDeactivationMsg: Label 'License Deactivated by Platform', Locked = true;
        EventTagLicensePlatformDeactivationTok: Label 'CAVSB1102', Locked = true;
        EventTagLicenseActivationFailureMsg: Label 'License Activation Failure', Locked = true;
        EventTagLicenseActivationFailureTok: Label 'CAVSB1100', Locked = true;
        EventTagLicenseCheckSuccessMsg: Label 'License Check - Success', Locked = true;
        EventTagLicenseCheckSuccessTok: Label 'CAVSB1200', Locked = true;
        EventTagLicenseCheckFailureMsg: Label 'License Check - Failed', Locked = true;
        EventTagLicenseCheckFailureTok: Label 'CAVSB1201', Locked = true;
        EventTagMisuseReportMsg: Label 'Misuse! Table data and IsoStorage mismatch', Locked = true;
        EventTagMisuseReportTok: Label 'CAVSB1300', Locked = true;
        EventTagVersionUpdateCheckMsg: Label 'Version Update Checking', Locked = true;
        EventTagVersionUpdateCheckTok: Label 'CAVSB1400', Locked = true;

    internal procedure LicensingAppInstalled()
    begin
        EmitTraceTag(EventTagInstallMsg, EventTagInstallTok);
    end;

    internal procedure LicensingAppUpgraded()
    begin
        EmitTraceTag(EventTagUpgradeMsg, EventTagUpgradeTok);
    end;

    internal procedure NewExtensionRegistered(var CAVExtensionLicense: Record "CAVSB Extension License")
    begin
        EmitTraceTag(CAVExtensionLicense, EventTagNewExtensionMsg, EventTagNewExtensionTok);
    end;

    internal procedure LicenseActivation(var CAVExtensionLicense: Record "CAVSB Extension License")
    begin
        EmitTraceTag(CAVExtensionLicense, EventTagLicenseActivationMsg, EventTagLicenseActivationTok);
    end;

    internal procedure LicenseDeactivation(var CAVExtensionLicense: Record "CAVSB Extension License")
    begin
        EmitTraceTag(CAVExtensionLicense, EventTagLicenseDeactivationMsg, EventTagLicenseDeactivationTok);
    end;

    internal procedure LicensePlatformDeactivation(var CAVExtensionLicense: Record "CAVSB Extension License")
    begin
        EmitTraceTag(CAVExtensionLicense, EventTagLicensePlatformDeactivationMsg, EventTagLicensePlatformDeactivationTok);
    end;

    internal procedure LicenseActivationFailure(var CAVExtensionLicense: Record "CAVSB Extension License")
    begin
        EmitTraceTag(CAVExtensionLicense, EventTagLicenseActivationFailureMsg, EventTagLicenseActivationFailureTok);
    end;

    internal procedure LicenseCheckSuccess(var CAVExtensionLicense: Record "CAVSB Extension License")
    begin
        EmitTraceTag(CAVExtensionLicense, EventTagLicenseCheckSuccessMsg, EventTagLicenseCheckSuccessTok);
    end;

    internal procedure LicenseCheckFailure(var CAVExtensionLicense: Record "CAVSB Extension License")
    begin
        EmitTraceTag(CAVExtensionLicense, EventTagLicenseCheckFailureMsg, EventTagLicenseCheckFailureTok);
    end;

    internal procedure EventTagMisuseReport(var CAVExtensionLicense: Record "CAVSB Extension License")
    begin
        EmitTraceTag(CAVExtensionLicense, EventTagMisuseReportMsg, EventTagMisuseReportTok);
    end;

    internal procedure VersionUpdateCheck(var CAVExtensionLicense: Record "CAVSB Extension License")
    begin
        EmitTraceTag(CAVExtensionLicense, EventTagVersionUpdateCheckMsg, EventTagVersionUpdateCheckTok);
    end;

    local procedure EmitTraceTag(EventDescriptionText: Text; Tag: Text)
    var
        TelemetryDimension: Dictionary of [Text, Text];
    begin
        Session.LogMessage(Tag, EventDescriptionText, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimension);
    end;

    local procedure EmitTraceTag(var CAVExtensionLicense: Record "CAVSB Extension License"; EventDescriptionText: Text; Tag: Text)
    var
        TraceTagMessage: Text;
        TelemetryDimension: Dictionary of [Text, Text];
        ExtensionNameLbl: Label 'ExtensionName', Locked = true;
        ExtensionGuidLbl: Label 'ExtensionGuid', Locked = true;
        ExtensionSubmoduleLbl: Label 'SubmoduleName', Locked = true;
        ExtensionPublisherLbl: Label 'Publisher', Locked = true;
        AppInfo: ModuleInfo;
    begin
        NavApp.GetModuleInfo(CAVExtensionLicense."Extension App Id", AppInfo);
        TraceTagMessage := EventDescriptionText;
        TelemetryDimension.Add(ExtensionNameLbl, CAVExtensionLicense."Extension Name");
        TelemetryDimension.Add(ExtensionGuidLbl, CAVExtensionLicense."Extension App Id");
        TelemetryDimension.Add(ExtensionPublisherLbl, AppInfo.Publisher);
        TelemetryDimension.Add(ExtensionSubmoduleLbl, CompanyName);
        Session.LogMessage(Tag, TraceTagMessage, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimension);
    end;
}
