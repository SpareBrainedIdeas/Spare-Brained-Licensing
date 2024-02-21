codeunit 71264328 "CAVSB Check Active Meth"
{
    Access = Internal;

    procedure CheckIfActive(var CAVExtensionLicense: Record "CAVSB Extension License") IsActive: Boolean
    var
        CAVSBDeactivateMeth: Codeunit "CAVSB Deactivate Meth";
        CAVSBEvents: Codeunit "CAVSB Events";
        CAVSBTelemetry: Codeunit "CAVSB Telemetry";
    begin
        IsActive := DoCheckIfActive(CAVExtensionLicense);

        // We throw the Event here before we begin to deactivate the subscription.
        CAVSBEvents.OnAfterCheckActiveBasic(CAVExtensionLicense, IsActive);

        if IsActive then
            CAVSBTelemetry.LicenseCheckSuccess(CAVExtensionLicense)
        else
            CAVSBTelemetry.LicenseCheckFailure(CAVExtensionLicense);

        if CAVExtensionLicense.Activated and not IsActive then
            // If the Check came back FALSE but the Subscription is Active,
            // it may be because the subscription has expired or deactivated on the platform.
            // We will force the local installation to inactive.
            CAVSBDeactivateMeth.Deactivate(CAVExtensionLicense, true);
    end;

    procedure DoCheckIfActive(var CAVExtensionLicense: Record "CAVSB Extension License"): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        CAVIsoStoreManager: Codeunit "CAVSB IsoStore Manager";
        CAVEvents: Codeunit "CAVSB Events";
        CAVSBTelemetry: Codeunit "CAVSB Telemetry";
        CAVSBVersionCheck: Codeunit "CAVSB Version Check";
        IsoActive: Boolean;
        GraceEndDate: Date;
        InstallDateTime: DateTime;
        IsoDatetime: DateTime;
        LastCheckDateTime: DateTime;
        IsoNumber: Integer;
        LicensePlatform: Interface "CAVSB ILicenseCommunicator";
        DaysGraceTok: Label '<+%1D>', Comment = '%1 is the number of days';
        GraceExpiringMsg: Label 'Today is the last trial day for %1. Please purchase a License Key and Activate the subscription to continue use.', Comment = '%1 is the name of the Extension';
        ResponseBody: Text;
        IsoStorageValue: Text;
        GracePeriodExpiredTok: Label 'Grace Period (End Date %1) Expired', Locked = true;
        SubscriptionExpiredTok: Label 'Subscription Period (Ended %1) Expired', Locked = true;
        IsoStorageTamperingTok: Label 'The IsoStorage and License record are different, which MAY indicate tampering or defects in the Platform.', Locked = true;
    begin
        LicensePlatform := CAVExtensionLicense."License Platform";

        // if the subscription isn't active, check if we're in the 'grace' preinstall window, which always includes the first day of use
        if not CAVExtensionLicense.Activated then begin
            if CAVIsoStoreManager.GetAppValue(CAVExtensionLicense, 'installDate', IsoStorageValue) then
                Evaluate(InstallDateTime, IsoStorageValue);
            if CAVIsoStoreManager.GetAppValue(CAVExtensionLicense, 'preactivationDays', IsoStorageValue) then
                Evaluate(IsoNumber, IsoStorageValue);
            if IsoNumber > 0 then
                GraceEndDate := CalcDate(StrSubstNo(DaysGraceTok, IsoNumber), DT2Date(InstallDateTime))
            else
                if (EnvironmentInformation.IsSandbox() and (IsoNumber < 0)) then
                    // -1 days grace for a Sandbox means it's unlimited use in sandboxes, even if not activated.
                    exit(true)
                else
                    GraceEndDate := Today;
            if (GraceEndDate = Today) and GuiAllowed then
                Message(GraceExpiringMsg, CAVExtensionLicense."Extension Name");

            // if the subscription isn't active, and we're not in the grace period, then we're not Active
            if GraceEndDate < Today then
                CAVEvents.OnAfterCheckActiveFailure(CAVExtensionLicense, false, StrSubstNo(GracePeriodExpiredTok, GraceEndDate));
            exit(GraceEndDate >= Today);
        end;

        if CAVIsoStoreManager.GetAppValue(CAVExtensionLicense, 'lastCheckDate', IsoStorageValue) then
            Evaluate(LastCheckDateTime, IsoStorageValue);
        if ((Today() - DT2Date(LastCheckDateTime)) > 0) then begin
            if LicensePlatform.CallAPIForVerification(CAVExtensionLicense, ResponseBody, false) then begin
                // This may update the End Dates - note: may or may not call .Modify
                LicensePlatform.PopulateSubscriptionFromResponse(CAVExtensionLicense, ResponseBody);
                CAVExtensionLicense.Modify();
            end;
            CAVSBVersionCheck.DoVersionCheck(CAVExtensionLicense);
            CAVIsoStoreManager.SetAppValue(CAVExtensionLicense, 'lastCheckDate', Format(CurrentDateTime, 0, 9));
        end;

        // if the subscription ran out
        if (CAVExtensionLicense."Subscription End Date" < CurrentDateTime) and
          (CAVExtensionLicense."Subscription End Date" <> 0DT)
        then begin
            CAVEvents.OnAfterCheckActiveFailure(CAVExtensionLicense, false, StrSubstNo(SubscriptionExpiredTok, CAVExtensionLicense."Subscription End Date"));
            exit(false);
        end;

        // if the record version IS active, then let's crosscheck against isolated storage
        if CAVIsoStoreManager.GetAppValue(CAVExtensionLicense, 'active', IsoStorageValue) then
            Evaluate(IsoActive, IsoStorageValue);
        if not IsoActive then begin
            LicensePlatform.ReportPossibleMisuse(CAVExtensionLicense);
            CAVSBTelemetry.EventTagMisuseReport(CAVExtensionLicense);
            CAVEvents.OnAfterCheckActiveFailure(CAVExtensionLicense, false, IsoStorageTamperingTok);
            exit(false);
        end;

        // Check Record end date against IsoStorage end date
        if CAVIsoStoreManager.GetAppValue(CAVExtensionLicense, 'endDate', IsoStorageValue) then
            Evaluate(IsoDatetime, IsoStorageValue);
        if IsoDatetime <> 0DT then
            // Only checking at the date level in case of time zone nonsense
            if DT2Date(IsoDatetime) <> DT2Date(CAVExtensionLicense."Subscription End Date") then begin
                LicensePlatform.ReportPossibleMisuse(CAVExtensionLicense);
                CAVSBTelemetry.EventTagMisuseReport(CAVExtensionLicense);
                CAVEvents.OnAfterCheckActiveFailure(CAVExtensionLicense, false, IsoStorageTamperingTok);
                exit(false);
            end;

        // Finally, all things checked out
        exit(true);
    end;
}
