codeunit 71035 "SPBPL Gumroad Communicator" implements "SPBPL ILicenseCommunicator"
{

    var
        GumroadVerifyAPITok: Label 'https://api.gumroad.com/v2/licenses/verify?product_permalink=%1&license_key=%2&increment_uses_count=%3', Comment = '%1 %2 %3', Locked = true;

    procedure CallAPIForVerification(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text; IncrementLicenseCount: Boolean) ResultOK: Boolean
    var
        NAVAppSetting: Record "NAV App Setting";
        EnvInformation: Codeunit "Environment Information";
        ApiHttpClient: HttpClient;
        ApiHttpRequestMessage: HttpRequestMessage;
        ApiHttpResponseMessage: HttpResponseMessage;
        VerifyAPI: Text;
        WebCallErr: Label 'Unable to verify or activate license.\ %1: %2 \ %3', Comment = '%1 %2 %3';
        EnvironmentBlockErr: Label 'Unable to communicate with the license server due to an environment block. Please resolve and try again.';
        AppInfo: ModuleInfo;
    begin
        // We REQUIRE HTTP access, so we'll force it on, regardless of Sandbox
        NavApp.GetCurrentModuleInfo(AppInfo);
        if NAVAppSetting.Get(AppInfo.Id) then begin
            if not NAVAppSetting."Allow HttpClient Requests" then begin
                NAVAppSetting."Allow HttpClient Requests" := true;
                NAVAppSetting.Modify();
            end
        end else begin
            NAVAppSetting."App ID" := AppInfo.Id;
            NAVAppSetting."Allow HttpClient Requests" := true;
            NAVAppSetting.Insert();
        end;

        VerifyAPI := StrSubstNo(GumroadVerifyAPITok, SPBExtensionLicense."Product Code", SPBExtensionLicense."License Key", Format(IncrementLicenseCount, 0, 9));
        ApiHttpRequestMessage.SetRequestUri(VerifyAPI);
        ApiHttpRequestMessage.Method('POST');

        if not ApiHttpClient.Send(ApiHttpRequestMessage, ApiHttpResponseMessage) then begin
            if ApiHttpResponseMessage.IsBlockedByEnvironment then begin
                if GuiAllowed() then
                    Error(EnvironmentBlockErr)
            end else
                if GuiAllowed() then
                    Error(WebCallErr, ApiHttpResponseMessage.HttpStatusCode, ApiHttpResponseMessage.ReasonPhrase, ApiHttpResponseMessage.Content);
        end else
            if ApiHttpResponseMessage.IsSuccessStatusCode() then begin
                ApiHttpResponseMessage.Content.ReadAs(ResponseBody);
                exit(true);
            end else
                if GuiAllowed() then
                    Error(WebCallErr, ApiHttpResponseMessage.HttpStatusCode, ApiHttpResponseMessage.ReasonPhrase, ApiHttpResponseMessage.Content);
    end;


    procedure ReportPossibleMisuse(SPBExtensionLicense: Record "SPBPL Extension License")
    begin
        // Potential future use of 'reporting' misuse attempts.   For example, someone programmatically changing the Subscription Record

        OnAfterThrowPossibleMisuse(SPBExtensionLicense);
    end;

#pragma warning disable AA0150 // TODO - Passed as "var" for the interface
    procedure PopulateSubscriptionFromResponse(var SPBExtensionLicense: Record "SPBPL Extension License"; var ResponseBody: Text)
#pragma warning restore AA0150
    var
        TempJsonBuffer: Record "JSON Buffer" temporary;
        TempPlaceholder: Text;
        AppInfo: ModuleInfo;
        GumroadJson: JsonObject;
        GumroadToken: JsonToken;
        ActivationFailureErr: Label 'An error occured validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
    begin
        NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
        GumroadJson.ReadFrom(ResponseBody);
        GumroadJson.Get('success', GumroadToken);
        if not GumroadToken.AsValue().AsBoolean() then
            if GuiAllowed() then
                Error(ActivationFailureErr, AppInfo.Publisher);
        GumroadJson.Get('purchase', GumroadToken);

        TempJsonBuffer.ReadFromText(ResponseBody);

        // Update the current Subscription record
        SPBExtensionLicense.Validate(Activated, true);
        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'license_key');
        SPBExtensionLicense."License Key" := CopyStr(TempPlaceholder, 1, MaxStrLen(SPBExtensionLicense."License Key"));
        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'created_at');
        Evaluate(SPBExtensionLicense."Created At", TempPlaceholder);
        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'subscription_ended_at');
        Evaluate(SPBExtensionLicense."Subscription Ended At", TempPlaceholder);
        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'subscription_cancelled_at');
        Evaluate(SPBExtensionLicense."Subscription Cancelled At", TempPlaceholder);
        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'subscription_failed_at');
        Evaluate(SPBExtensionLicense."Subscription Failed At", TempPlaceholder);

        TempJsonBuffer.GetPropertyValue(TempPlaceholder, 'email');
        SPBExtensionLicense."Subscription Email" := CopyStr(TempPlaceholder, 1, MaxStrLen(SPBExtensionLicense."Subscription Email"));
        SPBExtensionLicense.CalculateEndDate();
    end;

    procedure CheckAPILicenseCount(var SPBExtensionLicense: Record "SPBPL Extension License"; ResponseBody: Text): Boolean
    var
        TempJsonBuffer: Record "JSON Buffer" temporary;
        GumroadSPBLicenseUtilities: Codeunit "SPBPL License Utilities";
        LicenseUses: Integer;
        LicenseCount: Integer;
        AppInfo: ModuleInfo;
        GumroadJson: JsonObject;
        GumroadToken: JsonToken;
        GumroadErr: Label 'An error occured validating the license.  Contact %1 for assistance', Comment = '%1 is the App Publisher';
    begin
        // The 'Test' product, we never do a Count check on this application
        if SPBExtensionLicense."Entry Id" = GumroadSPBLicenseUtilities.GetTestProductAppId() then
            exit(true);

        GumroadJson.ReadFrom(ResponseBody);
        GumroadJson.Get('success', GumroadToken);
        if not GumroadToken.AsValue().AsBoolean() then begin
            NavApp.GetModuleInfo(SPBExtensionLicense."Extension App Id", AppInfo);
            if GuiAllowed() then
                Error(GumroadErr, AppInfo.Publisher);
        end;
        GumroadJson.Get('purchase', GumroadToken);

        TempJsonBuffer.ReadFromText(ResponseBody);
        TempJsonBuffer.GetIntegerPropertyValue(LicenseUses, 'uses');
        TempJsonBuffer.GetIntegerPropertyValue(LicenseCount, 'quantity');

        exit(LicenseUses < LicenseCount);
    end;

    procedure SampleKeyFormatText(): Text
    var
        GumroadKeyFormatTok: Label 'The key will look like XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX.';
    begin
        exit(GumroadKeyFormatTok);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterThrowPossibleMisuse(SPBExtensionLicense: Record "SPBPL Extension License")
    begin
    end;
}