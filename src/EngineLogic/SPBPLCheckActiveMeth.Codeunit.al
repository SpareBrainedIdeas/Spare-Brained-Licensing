codeunit 71043 "SPBPL Check Active Meth"
{
    Access = Internal;

    procedure CheckIfActive(var SPBExtensionLicense: Record "SPBPL Extension License") IsActive: Boolean
    var
        SPBPLDeactivateMeth: Codeunit "SPBPL Deactivate Meth";
        SPBPLEvents: Codeunit "SPBPL Events";
        SPBPLTelemetry: Codeunit "SPBPL Telemetry";
    begin
        IsActive := DoCheckIfActive(SPBExtensionLicense);

        // We throw the Event here before we begin to deactivate the subscription.
        SPBPLEvents.OnAfterCheckActiveBasic(SPBExtensionLicense, IsActive);

        if IsActive then
            SPBPLTelemetry.LicenseCheckSuccess(SPBExtensionLicense)
        else
            SPBPLTelemetry.LicenseCheckFailure(SPBExtensionLicense);

        if SPBExtensionLicense.Activated and not IsActive then
            // If the Check came back FALSE but the Subscription is Active,
            // it may be because the subscription has expired or deactivated on the platform.
            // We will force the local installation to inactive.
            SPBPLDeactivateMeth.Deactivate(SPBExtensionLicense, true);
    end;

    procedure DoCheckIfActive(var SPBExtensionLicense: Record "SPBPL Extension License"): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        SPBIsoStoreManager: Codeunit "SPBPL IsoStore Manager";
        SPBEvents: Codeunit "SPBPL Events";
        SPBPLTelemetry: Codeunit "SPBPL Telemetry";
        SPBPLVersionCheck: Codeunit "SPBPL Version Check";
        IsoActive: Boolean;
        GraceEndDate: Date;
        InstallDateTime: DateTime;
        IsoDatetime: DateTime;
        LastCheckDateTime: DateTime;
        IsoNumber: Integer;
        LicensePlatform: Interface "SPBPL ILicenseCommunicator";
        DaysGraceTok: Label '<+%1D>', Comment = '%1 is the number of days';
        GraceExpiringMsg: Label 'Today is the last trial day for %1. Please purchase a License Key and Activate the subscription to continue use.', Comment = '%1 is the name of the Extension';
        ResponseBody: Text;
        IsoStorageValue: Text;
        GracePeriodExpiredTok: Label 'Grace Period (End Date %1) Expired', Locked = true;
        SubscriptionExpiredTok: Label 'Subscription Period (Ended %1) Expired', Locked = true;
        IsoStorageTamperingTok: Label 'The IsoStorage and License record are different, which MAY indicate tampering or defects in the Platform.', Locked = true;
    begin
        LicensePlatform := SPBExtensionLicense."License Platform";

        // if the subscription isn't active, check if we're in the 'grace' preinstall window, which always includes the first day of use
        if not SPBExtensionLicense.Activated then begin
            if SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'installDate', IsoStorageValue) then
                Evaluate(InstallDateTime, IsoStorageValue);
            if SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'preactivationDays', IsoStorageValue) then
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
                Message(GraceExpiringMsg, SPBExtensionLicense."Extension Name");

            // if the subscription isn't active, and we're not in the grace period, then we're not Active
            if GraceEndDate < Today then
                SPBEvents.OnAfterCheckActiveFailure(SPBExtensionLicense, false, StrSubstNo(GracePeriodExpiredTok, GraceEndDate));
            exit(GraceEndDate >= Today);
        end;

        if SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'lastCheckDate', IsoStorageValue) then
            Evaluate(LastCheckDateTime, IsoStorageValue);
        if ((Today() - DT2Date(LastCheckDateTime)) > 0) then begin
            if LicensePlatform.CallAPIForVerification(SPBExtensionLicense, ResponseBody, false) then begin
                // This may update the End Dates - note: may or may not call .Modify
                LicensePlatform.PopulateSubscriptionFromResponse(SPBExtensionLicense, ResponseBody);
                SPBExtensionLicense.Modify();
            end;
            SPBPLVersionCheck.DoVersionCheck(SPBExtensionLicense);
            SPBIsoStoreManager.SetAppValue(SPBExtensionLicense, 'lastCheckDate', Format(CurrentDateTime, 0, 9));
        end;

        // if the subscription ran out
        if (SPBExtensionLicense."Subscription End Date" < CurrentDateTime) and
          (SPBExtensionLicense."Subscription End Date" <> 0DT)
        then begin
            SPBEvents.OnAfterCheckActiveFailure(SPBExtensionLicense, false, StrSubstNo(SubscriptionExpiredTok, SPBExtensionLicense."Subscription End Date"));
            exit(false);
        end;

        // if the record version IS active, then let's crosscheck against isolated storage
        if SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'active', IsoStorageValue) then
            Evaluate(IsoActive, IsoStorageValue);
        if not IsoActive then begin
            LicensePlatform.ReportPossibleMisuse(SPBExtensionLicense);
            SPBPLTelemetry.EventTagMisuseReport(SPBExtensionLicense);
            SPBEvents.OnAfterCheckActiveFailure(SPBExtensionLicense, false, IsoStorageTamperingTok);
            exit(false);
        end;

        // Check Record end date against IsoStorage end date
        if SPBIsoStoreManager.GetAppValue(SPBExtensionLicense, 'endDate', IsoStorageValue) then
            Evaluate(IsoDatetime, IsoStorageValue);
        if IsoDatetime <> 0DT then
            // Only checking at the date level in case of time zone nonsense
            if DT2Date(IsoDatetime) <> DT2Date(SPBExtensionLicense."Subscription End Date") then begin
                LicensePlatform.ReportPossibleMisuse(SPBExtensionLicense);
                SPBPLTelemetry.EventTagMisuseReport(SPBExtensionLicense);
                SPBEvents.OnAfterCheckActiveFailure(SPBExtensionLicense, false, IsoStorageTamperingTok);
                exit(false);
            end;

        // Finally, all things checked out
        exit(true);
    end;
}
