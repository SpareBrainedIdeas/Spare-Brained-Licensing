/// <summary>
/// This Codeunit is for checking basic active/inactive functions to be used by 3rd parties wanting to validate
/// if a license is active.  Two main options exist at this time - with or without Submodule functionality.
/// </summary>
codeunit 71042 "SPBPL Check Active"
{
    /// <summary>
    /// This function takes an App ID and checks if it is active or not, along with if the user should be shown errors if Inactive.
    /// </summary>
    /// <param name="SubscriptionId">This should be the App ID</param>
    /// <param name="InactiveShowError">If the extension is Inactive, should the user be shown an error?</param>
    /// <returns></returns>
    procedure CheckBasic(SubscriptionId: Guid; InactiveShowError: Boolean) IsActive: Boolean
    var
        SPBExtensionLicense: Record "SPBPL Extension License";
        SPBEvents: Codeunit "SPBPL Events";
        NoSubFoundErr: Label 'No License was found in the Licenses list for SubscriptionId: %1', Comment = '%1 is the ID of the App.';
    begin
        SPBExtensionLicense.SetRange("Extension App Id", SubscriptionId);
        //If using this function signature, the Submodule functionality should NOT be considered.
        SPBExtensionLicense.SetRange("Submodule Name", '');
        if not SPBExtensionLicense.FindFirst() then
            if GuiAllowed() then //TODO: Errors usually can be raised in non UI sessions such as API or Background sessions
                Error(NoSubFoundErr, SubscriptionId)
            else
                SPBEvents.OnAfterCheckActiveBasicFailure(SubscriptionId, '', StrSubstNo(FailureToFindSubscriptionTok, SPBExtensionLicense.GetFilters()));

        IsActive := DoCheckBasic(SPBExtensionLicense, InactiveShowError);
    end;

    /// <summary>
    /// This function takes an App ID and Submodule Name and checks if it is active or not, along with if the user should be shown errors if Inactive.
    /// </summary>
    /// <param name="SubscriptionId">This should be the App ID</param>
    /// <param name="SubmoduleName">This should be the submodule to check for</param>
    /// <param name="InactiveShowError">If the extension is Inactive, should the user be shown an error?</param>
    /// <returns></returns>
    procedure CheckBasicSubmodule(SubscriptionId: Guid; SubmoduleName: Text[100]; InactiveShowError: Boolean) IsActive: Boolean
    var
        SPBExtensionLicense: Record "SPBPL Extension License";
        SPBEvents: Codeunit "SPBPL Events";
        NoSubscriptionFoundErr: Label 'No License was found in the Licenses list for SubscriptionId: %1 with Submodule name: %2', Comment = '%1 is the ID of the App. %2 is the Submodule.';
    begin
        SPBExtensionLicense.SetRange("Extension App Id", SubscriptionId);
        SPBExtensionLicense.SetRange("Submodule Name", SubmoduleName);
        if not SPBExtensionLicense.FindFirst() then
            if GuiAllowed() then //TODO: Errors usually can be raised in non UI sessions such as API or Background sessions
                Error(NoSubscriptionFoundErr, SubscriptionId, SubmoduleName)
            else
                SPBEvents.OnAfterCheckActiveBasicFailure(SubscriptionId, SubmoduleName, StrSubstNo(FailureToFindSubscriptionTok, SPBExtensionLicense.GetFilters()));

        IsActive := DoCheckBasic(SPBExtensionLicense, InactiveShowError);
    end;

    local procedure DoCheckBasic(var SPBExtensionLicense: Record "SPBPL Extension License"; InactiveShowError: Boolean): Boolean
    var
        SPBPLCheckActiveMeth: Codeunit "SPBPL Check Active Meth";
        IsActive: Boolean;
        SubscriptionInactiveErr: Label 'The License for %1 is not Active.  Contact your system administrator to re-activate it.', Comment = '%1 is the name of the Extension.';
    begin
        IsActive := SPBPLCheckActiveMeth.CheckIfActive(SPBExtensionLicense);
        if not IsActive and InactiveShowError then
            if GuiAllowed() then //TODO: Errors usually can be raised in non UI sessions such as API or Background sessions
                Error(SubscriptionInactiveErr, SPBExtensionLicense."Extension Name");
        exit(IsActive);
    end;

    var
        FailureToFindSubscriptionTok: Label 'Unable to find Subscription Entry (Filters %1)', Locked = true;
}
