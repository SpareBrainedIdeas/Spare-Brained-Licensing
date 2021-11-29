page 71034 "SPBPL License Activation"
{

    Caption = 'Licensing Activation Wizard';
    PageType = NavigatePage;
    SourceTable = "SPBPL Extension License";

    layout
    {
        area(content)
        {
            group(Step1)
            {
                Visible = Step1Visible;
                group(WelcomeText)
                {
                    Caption = 'This is the Activation Wizard for the Licensing system.';
                    group(WelcomeExplainer)
                    {
                        ShowCaption = false;
                        InstructionalText = 'You will enter the License Key for the following License.  If you do not have a License key, please click on the "Get License Key" link.';
                    }
                    field(LicenseLinkField; LicenseLinkText)
                    {
                        DrillDown = true;
                        Editable = false;
                        ShowCaption = false;
                        ApplicationArea = All;

                        trigger OnDrillDown()
                        begin
                            SPBPLLicenseUtilities.LaunchProductUrl(Rec);
                        end;
                    }
                }
                group(LetsStart)
                {
                    Caption = 'Start Activation';
                    group(StartText)
                    {
                        ShowCaption = false;
                        InstructionalText = 'Click Next to begin the activation process. You will need your Subscription License key.';
                    }
                }
            }
            group(Step2)
            {
                Visible = Step2Visible;

                group(LicenseKeyInstruction)
                {
                    ShowCaption = false;
                    InstructionalText = 'Please enter your Subscription License Key:';
                }
                field(LicenseKeyField; LicenseKey)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ShowCaption = false;
                }
                field(LicenseKeyFormat; LicenseFormatHintText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                }
            }
            group(Step2Test)
            {
                Visible = Step2TestVisible;

                group(TestPathLicenseKeyInstruction)
                {
                    ShowCaption = false;
                    InstructionalText = 'Please enter your Subscription License Key:';
                }
                field(TestPathLicenseKeyField; LicenseKey)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ShowCaption = false;
                }
                field(TestPathLicenseKeyFormat; LicenseFormatHintText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                }
                group(TestLicenseOption)
                {
                    ShowCaption = false;
                    InstructionalText = 'This is the Test Subscription, so you can use a test License Key here by clicking:';
                }
                field(TestLicenseHint; TestLicenseLinkText)
                {
                    DrillDown = true;
                    Editable = false;
                    ShowCaption = false;
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        LicenseKey := SPBPLLicenseUtilities.GetTestProductKey();
                    end;
                }
            }
            group(Step3)
            {
                Visible = Step3Visible;
                group(ActivationResultsPageText)
                {
                    Caption = 'Activation Results';
                    group(ActivationWorked)
                    {
                        Visible = ActivationResult;
                        InstructionalText = 'Activation Successful!';
                        ShowCaption = false;
                    }
                    group(ActivationDidNotWork)
                    {
                        Visible = not ActivationResult;
                        InstructionalText = 'Activation Unsuccessful!';
                        ShowCaption = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    if (Step = Step::Step2) and (LicenseKey = '') then
                        Error(LicenseKeyNeededErr);
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    var
        SPBPLLicenseManagement: Codeunit "SPBPL License Management";
        SPBPLLicenseUtilities: Codeunit "SPBPL License Utilities";
        LicenseLinkText: Text;
        LicenseKey: Text;
        LicenseFormatHintText: Text;
        TestLicenseLinkText: Text;
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step2TestVisible: Boolean;
        Step3Visible: Boolean;
        Step: Option Start,Step2,Step2Test,Finish;
        BackActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        LicenseLinkUriTok: Label 'Get License Key';
        LicenseKeyNeededErr: Label 'You need to enter a License Key to continue.';
        TestLicenseKeyOfferTok: Label 'Use Test Key';
        ActivationResult: Boolean;
        ShowAsTestSubscription: Boolean;


    trigger OnOpenPage()
    var
        LicensePlatform: Interface "SPBPL ILicenseCommunicator";
    begin
        LicenseLinkText := LicenseLinkUriTok;
        LicensePlatform := Rec."License Platform";
        LicenseFormatHintText := LicensePlatform.SampleKeyFormatText();
        Step := Step::Start;
        EnableControls();
    end;

    trigger OnAfterGetRecord()
    begin
        ShowAsTestSubscription := Rec.IsTestSubscription();
        TestLicenseLinkText := TestLicenseKeyOfferTok;
    end;

    local procedure EnableControls();
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStep1();
            Step::Step2:
                ShowStep2();
            Step::Finish:
                ShowStep3();
        end;
    end;

    local procedure FinishAction();
    begin
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean);
    begin
        // Validation trigger when moving from Step2 to 3
        if (Step = Step::Step2) and not Backwards then begin
            Rec."License Key" := CopyStr(LicenseKey, 1, MaxStrLen(Rec."License Key"));
            ActivationResult := SPBPLLicenseManagement.ActivateFromWizard(Rec);
            Step := Step + 1;
        end;

        if Backwards then
            Step := Step - 1
        ELSE
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStep1();
    begin
        Step1Visible := true;

        FinishActionEnabled := false;
        BackActionEnabled := false;
    end;

    local procedure ShowStep2();
    begin
        if ShowAsTestSubscription then
            Step2TestVisible := true
        else
            Step2Visible := true;
    end;

    local procedure ShowStep3();
    begin
        Step3Visible := true;

        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ResetControls();
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;

        Step1Visible := false;
        Step2Visible := false;
        Step2TestVisible := false;
        Step3Visible := false;
    end;


}
