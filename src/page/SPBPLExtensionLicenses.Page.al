page 71033 "SPBPL Extension Licenses"
{

    ApplicationArea = All;
    Caption = 'Extension Licenses';
    PageType = List;
    SourceTable = "SPBPL Extension License";
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry Id"; Rec."Entry Id")
                {
                    ToolTip = 'Specifies the value of the Entry Id field.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Extension Name"; Rec."Extension Name")
                {
                    ToolTip = 'The name of the Extension that is registered to have a Subscription requirement.';
                    ApplicationArea = All;
                    StyleExpr = SubscriptionStatusStyle;
                }
                field(Activated; Rec.Activated)
                {
                    ToolTip = 'Shows if this Extension has been Activated with a Product Key.';
                    ApplicationArea = All;
                }
                field(UpdateLink; UpdateLink)
                {
                    Caption = 'Update News';
                    ToolTip = 'If an Update is available, this will link to where to find out more.';
                    ApplicationArea = All;
                    DrillDown = true;
                    Style = Favorable;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(Rec."Update News URL");
                    end;
                }
                field("Trial Grace End Date"; Rec."Trial Grace End Date")
                {
                    ToolTip = 'If the Extension is not yet Activated, this is the last date the Extension can run in Trial Mode.';
                    ApplicationArea = All;
                }
                field("Subscription Email"; Rec."Subscription Email")
                {
                    ToolTip = 'This shows the email address that the License Key is registered to, in case there is a need to find it later.';
                    ExtendedDatatype = EMail;
                    ApplicationArea = All;
                }
                field("Product URL"; Rec."Product URL")
                {
                    ToolTip = 'The page where one can find more information about purchasing a Subscription for this Extension.';
                    ApplicationArea = All;
                    ExtendedDatatype = URL;
                }
                field("Support URL"; Rec."Support URL")
                {
                    ToolTip = 'The page where one can find more information about how to get Support for the Extension.';
                    ApplicationArea = All;
                    ExtendedDatatype = URL;
                }
                field("Billing Support Email"; Rec."Billing Support Email")
                {
                    ToolTip = 'The email address to contact with Billing related questions about this Subscription.';
                    ApplicationArea = All;
                    ExtendedDatatype = EMail;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActivateProduct)
            {
                ApplicationArea = All;
                Caption = 'Activate';
                Enabled = not Rec.Activated and UserHasWritePermission;
                Image = SuggestElectronicDocument;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Launches the Activation Wizard for this Subscription.';

                trigger OnAction()
                var
                    SPBLicenseManagement: Codeunit "SPBPL License Management";
                begin
                    SPBLicenseManagement.LaunchActivation(Rec);
                    Rec.SetRange("Entry Id");
                end;
            }
            action(DeactivateProduct)
            {
                ApplicationArea = All;
                Caption = 'Deactivate';
                Enabled = Rec.Activated and UserHasWritePermission;
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Forces this Subscription inactive, which will allow entry of a new License Key.';

                trigger OnAction()
                var
                    SPBLicenseManagement: Codeunit "SPBPL License Management";
                begin
                    SPBLicenseManagement.DeactivateExtension(Rec);
                    Rec.SetRange("Entry Id");
                end;
            }

        }
    }

    var
        UserHasWritePermission: Boolean;
        SubscriptionStatusStyle: Text;
        UpdateLink: Text;
        UpdateAvailableTok: Label 'Available';

    trigger OnOpenPage()
    begin
        // necessary since Enabled can't be bound to procedures.
        UserHasWritePermission := Rec.WritePermission;

        if UserHasWritePermission then
            CheckAllForUpdates();
    end;

    trigger OnAfterGetRecord()
    begin
        SetSubscriptionStyle();

        if Rec."Update Available" and (Rec."Update News URL" <> '') then
            UpdateLink := UpdateAvailableTok
        else
            UpdateLink := '';
    end;

    local procedure SetSubscriptionStyle()
    begin
        SubscriptionStatusStyle := 'Standard';
        if Rec.Activated then begin
            if (Rec."Subscription End Date" = 0DT) then
                SubscriptionStatusStyle := 'Favorable'
            else
                if (Rec."Subscription End Date" > CurrentDateTime) then
                    SubscriptionStatusStyle := 'Attention';
        end else
            if (Rec."Trial Grace End Date" <> 0D) then
                if (Rec."Trial Grace End Date" < Today) then
                    SubscriptionStatusStyle := 'StandardAccent'
                else
                    SubscriptionStatusStyle := 'Ambiguous'
            else
                SubscriptionStatusStyle := 'Unfavorable';
    end;

    local procedure CheckAllForUpdates()
    var
        SPBPLExtensionLicense: Record "SPBPL Extension License";
        SPBPLLicenseManagement: Codeunit "SPBPL License Management";
    begin
        if SPBPLExtensionLicense.FindSet(true) then
            repeat
                if SPBPLExtensionLicense."Update News URL" <> '' then
                    SPBPLLicenseManagement.DoVersionCheck(SPBPLExtensionLicense);
            until SPBPLExtensionLicense.Next() = 0;
    end;
}