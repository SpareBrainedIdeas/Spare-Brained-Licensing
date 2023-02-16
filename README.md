# Spare Brained Licensing

This is the public version repository for the Microsoft Dynamics 365 Business Central extension called **Spare Brained Licensing**.  The extension is available in [AppSource](https://appsource.microsoft.com/en-us/product/dynamics-365-business-central/PUBID.sparebrainedideasab1634968562109%7CAID.sparebrainedlicensing%7CPAPPID.5ddd2a5e-1b5f-47b4-b655-88d2c2a9b382-preview?flightCodes=sparebrainedlicensing&tab=DetailsAndSupport) for use in SaaS.  It is mirrored here, renumbered (and with a nonconflicting prefix) for PTE and easier On-Prem use for partners or anyone else who wants to compile and change things.  Functionally, the code is identical to the SaaS offering.

Below is a copy of the original [Blog Post](https://sparebrained.com/2021/11/free-monetization-licensing-tool-spare-brained-licensing/) announcing the project, markdown-ified.

## What It Does
The Spare Brained Licensing app is a gatekeeper, a virtual bouncer. It is built on the idea that an Extension should have an active License Key, and provides the hooks for Extensions to check if the subscription license is active.

The user/administrator gets a single page where they can find all of their Subscriptions:

![Business Central screen showing a list of Extension Licenses](https://sparebrained.com/wp-content/uploads/2021/11/licenses.png)

Screenshot showing a Business Central window titled Extension Licenses, with columns for the Extension Name, Activated, Update News, Trial Grace End Date Subscription Email and more off screen.
(Screenshot showing a Business Central window titled Extension Licenses, with columns described in the text below)

Currently, this has support to:

- Which Extensions installed are managed by this Licensing system
- Showing Activation status, as well as allowing users to Activate/Deactivate a License (in the system, financials are externally managed)
- Daily checks for updated versions will show users (and create related User Tasks) if there is an update available
- If an extension is running under a “Trial Grace” period, when does that end?
- Which email address is on file at the Subscription provider associated with the License Key, so you can find any update or billing emails
- The Product URL page so you can quickly find more information
- The Billing Support email for that extension, so you can quickly contact the publisher involved

## Features for Publishers

Along with all of the above, as an Extension/App publisher, you are able to register all of the information above in any way you choose, which allows for easy handling of:

- Grace Periods can vary by environment type, such as allow a 1 week trial in production, and longer (or even infinite) Grace Periods in Sandbox
- You can easily ‘check’ if a license is active, getting back either a simple true/false silently to handle yourself or automatically pop a warning message to users trying to use your Application.
- There are great events available for activation, making it easy to guide your user to a Setup or Onboarding Wizard from the minute they activate

## License Key Framework
This is a License Key validation and management framework, which does mean it does not manage subscription billing or any of the financial aspects of the monetization for you at this time.

However, the core table has been implemented as an Enum/Interface system. This extension comes with built-in support for using Gumroad as a license platform, but you can extend it to support almost anything.

### Licensing Systems Interfaces
Out of the box, this extension has support for the Gumroad and Lemon Squeezy platforms, making it very simple for smaller partners or even single developers to quickly and easily:

- Offer complex rates per month, quarter, half year, and annually in a variety of currencies
- Payout is handled automatically by Gumroad or Lemon Squeezy to you, either by direct transfer or PayPal (varies by country)
- Easily support Affiliate handling to offer partners a % payout, which will also be managed by Gumroad on your behalf
- All VAT handling, including MOSS reporting, is done by Gumroad or Lemon Squeezy on your behalf, so you only have to worry about the Net
- Built-In Customer Email List building, along with easy integrations with third parties to communicate with your market
- Fees vary, and you should consult the respective pricing pages on either platform for the latest information

### Extensible
Because the framework is extensible, publishers can also extend the Licensing system to add other License Key verification platforms as wanted.   Simply extend the "Platform" enum, and implement a Communication Interface, and it'll tick right along as before.

## How can I trust it?
Valid question! This application does communicate to outside systems in a very narrow scope.  You are welcome and encouraged to review the source code in detail and make us aware of any faults.  We have had multiple code reviews by other MVPs to see if there is any way to circumvent the solution's protections, and that has not been possible.

## What’s the Catch?
None. We needed a Licensing verification system for our great low-code Business Central API Designer tool, Data Braider, so the intention from inception was to make this extension available for more people to use.
