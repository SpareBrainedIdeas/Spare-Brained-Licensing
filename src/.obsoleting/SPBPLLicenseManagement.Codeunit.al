codeunit 71036 "CAVSB License Management"
{
    Permissions = tabledata "CAVSB Extension License" = RIM;
    ObsoleteState = Pending;
    ObsoleteReason = 'Refactored to new Method Codeunits and separate Event wrapper.';

    [Obsolete('Use new Events in CAVSB Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterLicenseDeactivated(var SPBExtensionLicense: Record "CAVSB Extension License")
    begin
    end;

    [Obsolete('Use new Events in CAVSB Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterLicenseDeactivatedByPlatform(var SPBExtensionLicense: Record "CAVSB Extension License"; ResponseBody: Text)
    begin
    end;

    [Obsolete('Use new Events in CAVSB Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterActivationFailure(var SPBExtensionLicense: Record "CAVSB Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [Obsolete('Use new Events in CAVSB Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeVersionCheckUpgradeAvailable(var SPBExtensionLicense: Record "CAVSB Extension License"; var LatestVersion: Version; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Use new Events in CAVSB Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterActivationSuccess(var SPBExtensionLicense: Record "CAVSB Extension License"; var AppInfo: ModuleInfo)
    begin
    end;

    [Obsolete('Use new Events in CAVSB Events codeunit.')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterVersionCheckFailure(var SPBExtensionLicense: Record "CAVSB Extension License"; var ApiHttpRespMessage: HttpResponseMessage)
    begin
    end;

    [Obsolete('Use new Events in CAVSB Events codeunit.')]
    [IntegrationEvent(false, false)]
    internal procedure OnAfterThrowPossibleMisuse(var SPBExtensionLicense: Record "CAVSB Extension License")
    begin
    end;
}
