/// <summary>
/// This Codeunit is for checking basic active/inactive functions to be used by 3rd parties wanting to validate
/// if a license is active.  Two main options exist at this time - with or without Submodule functionality.
/// </summary>
codeunit 71264325 "CAVSB Check Active"
{
    /// <summary>
    /// This function takes an App ID and checks if it is active or not, along with if the user should be shown errors if Inactive.
    /// </summary>
    /// <param name="SubscriptionId">This should be the App ID</param>
    /// <param name="InactiveShowError">If the extension is Inactive, should the user be shown an error?</param>
    /// <returns></returns>
    procedure CheckBasic(SubscriptionId: Guid; InactiveShowError: Boolean) IsActive: Boolean
    var
        CAVExtensionLicense: Record "CAVSB Extension License";
        CAVEvents: Codeunit "CAVSB Events";
        NoSubFoundErr: Label 'No License was found in the Licenses list for SubscriptionId: %1', Comment = '%1 is the ID of the App.';
    begin
        CAVExtensionLicense.SetRange("Extension App Id", SubscriptionId);
        //If using this function signature, the Submodule functionality should NOT be considered.
        CAVExtensionLicense.SetRange("Submodule Name", '');
        if not CAVExtensionLicense.FindFirst() then
            if GuiAllowed() then
                Error(NoSubFoundErr, SubscriptionId)
            else
                CAVEvents.OnAfterCheckActiveBasicFailure(SubscriptionId, '', StrSubstNo(FailureToFindSubscriptionTok, CAVExtensionLicense.GetFilters()));

        IsActive := DoCheckBasic(CAVExtensionLicense, InactiveShowError);
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
        CAVExtensionLicense: Record "CAVSB Extension License";
        CAVEvents: Codeunit "CAVSB Events";
        NoSubscriptionFoundErr: Label 'No License was found in the Licenses list for SubscriptionId: %1 with Submodule name: %2', Comment = '%1 is the ID of the App. %2 is the Submodule.';
    begin
        CAVExtensionLicense.SetRange("Extension App Id", SubscriptionId);
        CAVExtensionLicense.SetRange("Submodule Name", SubmoduleName);
        if not CAVExtensionLicense.FindFirst() then
            if GuiAllowed() then
                Error(NoSubscriptionFoundErr, SubscriptionId, SubmoduleName)
            else
                CAVEvents.OnAfterCheckActiveBasicFailure(SubscriptionId, SubmoduleName, StrSubstNo(FailureToFindSubscriptionTok, CAVExtensionLicense.GetFilters()));

        IsActive := DoCheckBasic(CAVExtensionLicense, InactiveShowError);
    end;

    local procedure DoCheckBasic(var CAVExtensionLicense: Record "CAVSB Extension License"; InactiveShowError: Boolean): Boolean
    var
        CAVSBCheckActiveMeth: Codeunit "CAVSB Check Active Meth";
        IsActive: Boolean;
        SubscriptionInactiveErr: Label 'The License for %1 is not Active.  Contact your system administrator to re-activate it.', Comment = '%1 is the name of the Extension.';
    begin
        IsActive := CAVSBCheckActiveMeth.CheckIfActive(CAVExtensionLicense);
        if not IsActive and InactiveShowError then
            if GuiAllowed() then
                Error(SubscriptionInactiveErr, CAVExtensionLicense."Extension Name");
        exit(IsActive);
    end;

    var
        FailureToFindSubscriptionTok: Label 'Unable to find Subscription Entry (Filters %1)', Locked = true;
}
