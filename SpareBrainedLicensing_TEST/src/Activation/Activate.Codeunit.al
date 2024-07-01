codeunit 90007 "TST Activate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ExtensionLicense: Record "SPBLIC Extension License";
        Assert: Codeunit "Assert";
        LibraryLicensing: Codeunit "TST Library - Licensing";

        IsInitialized: Boolean;

#pragma warning disable AA0005
    procedure Initialize()
    begin
        if not IsInitialized then begin
            LibraryLicensing.CreateAppRegistration(ExtensionLicense);
            IsInitialized := true;
        end;
    end;
#pragma warning restore AA0005

    // Scenario: Basic activation using Mock service
    [Test]
    procedure CanActivate()
    var
        SPBLICActivateMeth: Codeunit "SPBLIC Activate Meth";
        Activated: Boolean;
    begin
        Initialize();

        // When we activate the license
        Activated := SPBLICActivateMeth.Activate(ExtensionLicense);

        // Then the license should be activated
        Assert.IsTrue(Activated, 'The license should be activated');

        // And the license should be activated in the local system
        Assert.AreEqual(ENum::"SPBLIC License State"::Active, ExtensionLicense."License State", 'The license should be activated in the local system');
    end;

    // Scenario: Basic deactivation using Mock Service, local only first
    [Test]
    procedure CanDeactivate()
    var
        SPBLICDeactivateMeth: Codeunit "SPBLIC Deactivate Meth";
        Deactivated: Boolean;
    begin
        Initialize();

        // When we deactivate the license
        Deactivated := SPBLICDeactivateMeth.Deactivate(ExtensionLicense, false);  // False here says to disregard the platform, local force deactivation

        // Then the license should be deactivated
        Assert.IsTrue(Deactivated, 'The license should be deactivated');

        // And the license should be deactivated in the local system
        Assert.AreEqual(ENum::"SPBLIC License State"::Deactivated, ExtensionLicense."License State", 'The license should be deactivated in the local system');
    end;

    // Scenario: Basic deactivation using Mock Service, now via platform
    [Test]
    procedure CanDeactivateViaPlatform()
    var
        SPBLICDeactivateMeth: Codeunit "SPBLIC Deactivate Meth";
        Deactivated: Boolean;
    begin
        Initialize();

        // When we deactivate the license
        Deactivated := SPBLICDeactivateMeth.Deactivate(ExtensionLicense, true);  // True here says to use the platform for deactivation

        // Then the license should be deactivated
        Assert.IsTrue(Deactivated, 'The license should be deactivated');

        // And the license should be deactivated in the local system
        Assert.AreEqual(ENum::"SPBLIC License State"::Deactivated, ExtensionLicense."License State", 'The license should be deactivated in the local system');
    end;
}
