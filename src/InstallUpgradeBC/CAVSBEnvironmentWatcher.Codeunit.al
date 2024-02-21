codeunit 71047 "CAVSB Environment Watcher"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Triggers", 'OnAfterCopyEnvironmentPerDatabase', '', false, false)]
    local procedure DeactivateLicensesWhenEnvironmentCopied(DestinationEnvironmentType: Option Production,Sandbox)
    var
        SPBExtensionLicense: Record "CAVSB Extension License";
        CAVSBDeactivateMeth: Codeunit "CAVSB Deactivate Meth";
        GraceDaysMathTok: Label '<+%1D>', Locked = true;
    begin
        if SPBExtensionLicense.FindSet(true) then
            repeat
                if DestinationEnvironmentType = DestinationEnvironmentType::Sandbox then begin
                    // Reset all licenses to Sandbox grace
                    if SPBExtensionLicense."Sandbox Grace Days" <> 0 then
                        SPBExtensionLicense."Trial Grace End Date" := CalcDate(StrSubstNo(GraceDaysMathTok, SPBExtensionLicense."Sandbox Grace Days"), Today);
                    CAVSBDeactivateMeth.Deactivate(SPBExtensionLicense, false);
                end else
                    // Deactive the licenses in general
                    CAVSBDeactivateMeth.Deactivate(SPBExtensionLicense, false);
            until SPBExtensionLicense.Next() = 0;
    end;
}
