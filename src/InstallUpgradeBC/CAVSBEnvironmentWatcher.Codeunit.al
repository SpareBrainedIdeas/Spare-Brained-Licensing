codeunit 71264332 "CAVSB Environment Watcher"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Triggers", 'OnAfterCopyEnvironmentPerDatabase', '', false, false)]
    local procedure DeactivateLicensesWhenEnvironmentCopied(DestinationEnvironmentType: Option Production,Sandbox)
    var
        CAVExtensionLicense: Record "CAVSB Extension License";
        CAVSBDeactivateMeth: Codeunit "CAVSB Deactivate Meth";
        GraceDaysMathTok: Label '<+%1D>', Locked = true;
    begin
        if CAVExtensionLicense.FindSet(true) then
            repeat
                if DestinationEnvironmentType = DestinationEnvironmentType::Sandbox then begin
                    // Reset all licenses to Sandbox grace
                    if CAVExtensionLicense."Sandbox Grace Days" <> 0 then
                        CAVExtensionLicense."Trial Grace End Date" := CalcDate(StrSubstNo(GraceDaysMathTok, CAVExtensionLicense."Sandbox Grace Days"), Today);
                    CAVSBDeactivateMeth.Deactivate(CAVExtensionLicense, false);
                end else
                    // Deactive the licenses in general
                    CAVSBDeactivateMeth.Deactivate(CAVExtensionLicense, false);
            until CAVExtensionLicense.Next() = 0;
    end;
}
