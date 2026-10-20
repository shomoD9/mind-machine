# Resurfacing surfaces: what each platform permits

Research date: 20 October 2026, Asia/Kolkata. Primary documentation reviewed; no browser session, prototype, native app integration, account setup or message delivery was tested. No implementation stack is selected. Messaging requirements below describe platform/provider policies, not legal conclusions.

**Subsequent product decisions:** the human clarified “once” as **one item per encounter, repeats allowed**; selected ideas/bookmarks with private details retained inside the vault; required accepted reminders for timed messages; and selected browser feeds plus new-tab/messages on iPhone. Open alternatives below record the questions at research time; [ticket 20](../issues/20-headless-second-brain.md) contains current answers and the next frontier.

Mac browser feeds and browser new tabs are plausible places for app-generated resurfacing. Inserting content into native iPhone X or YouTube feeds has no supported route in the reviewed platform contract. WhatsApp and SMS can deliver opted-in cues, but introduce delivery dependencies and a separate content-disclosure boundary.

## Confirmed product context

The current direction is iPhone plus Mac at first release, a secondary iPhone keyboard, private sync, and explicit opt-in for cloud AI. The user rejected a keyboard resurfacing card and wants their own material to reappear in X scrolling, YouTube Shorts, WhatsApp/SMS deadline cues, and browser new tabs. The meaning of “resurfacing always happens once” remains unresolved. This report preserves all desired surfaces while distinguishing documented routes from unavailable or untested behavior.

## Primary-source register

All sources reviewed on 20 October 2026. A documented API is evidence of a capability; it does not prove this product works on a particular host site or passes store/platform review.

| ID | Source | Evidence status |
|---|---|---|
| R01 | [Chrome: Content scripts](https://developer.chrome.com/docs/extensions/develop/concepts/content-scripts) | Current official documentation: change webpage DOM, isolated JavaScript execution, matching websites and host permissions. |
| R02 | [Chrome: Override Chrome pages](https://developer.chrome.com/docs/extensions/develop/ui/override-chrome-pages) | Live official documentation with an old displayed update date; New Tab override is documented, with an incognito exclusion. |
| R03 | [Apple: Creating a Safari web extension](https://developer.apple.com/documentation/safariservices/creating-a-safari-web-extension) | Current official documentation: Safari webpage extensions on iOS and macOS. |
| R04 | [Apple: Managing Safari web extension permissions](https://developer.apple.com/documentation/safariservices/managing-safari-web-extension-permissions) | Current official documentation: website access grants and matching scripts. |
| R05 | [Apple: Explore Safari Web Extension improvements](https://developer.apple.com/videos/play/wwdc2021/10027/) | Official historical WWDC21 demonstration of new-tab overrides; closing transcript explicitly says the demonstrated APIs work on iOS as well as macOS. |
| R06 | [Apple: Adopting New Safari Web Extension APIs](https://developer.apple.com/documentation/safariservices/adopting-new-safari-web-extension-apis) | Current sample page linked to WWDC21; new-tab customization with iOS/macOS targets. |
| R07 | [Apple Platform Security: Security of runtime process](https://support.apple.com/guide/security/security-of-runtime-process-sec15bfe098e/web) | Official platform security contract: app sandbox prevents modification of other apps; cross-app services must be explicitly supplied by the OS. |
| R08 | [WhatsApp Business Messaging Policy](https://business.whatsapp.com/policy) | Live official URL redirects to whatsappbusiness.com; policy dated 23 September 2026. Consent, sender identity, templates, service window and opt-out. |
| R09 | [WhatsApp: Privacy Protections](https://whatsappbusiness.com/privacy-protections/) | Current official business privacy page; transport protection and business-hosting/partner distinction. Contains legacy pricing language, which is not used as evidence here. |
| R10 | [Twilio: Messages resource](https://www.twilio.com/docs/messaging/api/message-resource) | Current provider documentation: outgoing content, queued/sent/delivered/failed distinctions, SMS segmentation and channel-specific read receipts. Provider example, not a choice of vendor. |
| R11 | [Twilio: Message Redaction](https://www.twilio.com/docs/messaging/guides/privacy-message-redaction) | Current provider documentation: access to plaintext content during processing and limits of redaction, including retained data. |
| R12 | [Twilio Messaging Policy](https://www.twilio.com/en-us/legal/messaging-policy) | Provider policy dated 13 April 2026: informed consent, sender identification, opt-out and proof of consent. |
| R13 | [Apple: MFMessageComposeViewController](https://developer.apple.com/documentation/messageui/mfmessagecomposeviewcontroller) | Current official documentation: user-facing SMS/MMS composer; user sends or cancels. |

## Surface contracts

| Desired surface | Documented path | Constraint and evidence | Product implication |
|---|---|---|---|
| Own thought appears while scrolling X on Mac | Chrome extension changes the X **website** through a content script. | Webpage DOM modification requires applicable site permission. Extension installation and grants are necessary. [R01] Actual X feed placement/scrolling is untested. | A visibly app-branded “From your notes” cue inside the webpage is plausible. This does not create a real X post or publish the thought to followers. |
| Bookmark appears during YouTube Shorts on Mac | Chrome extension changes the **web** Shorts page. | Same browser capability, different website integration. [R01] Dynamic layouts, navigation and fullscreen behavior require testing. | An app-authored bookmark cue could appear alongside or between web items. It should not masquerade as a creator-uploaded Short. |
| These experiences in Safari on iPhone/Mac | Safari web extension applies to permitted Safari websites. | Apple documents iOS/macOS extension targets and website grants. [R03, R04] Host-site compatibility, exact feed insertion and web-app/in-app-browser contexts remain untested. | Possible website equivalents require the user to browse there. Do not silently translate the user's native-app request into Safari usage. |
| Own thought appears inside the **native iPhone X app** | No supported path established. | App sandbox prevents third-party apps modifying another app; only explicitly offered system services cross boundaries. [R07] | A browser extension cannot satisfy this native-app promise. It would require platform cooperation or a changed experience. |
| Bookmark appears inside **native iPhone YouTube Shorts** | No supported path established. | Same sandbox boundary. [R07] Keyboard extensions also cannot appear as a passive scrolling overlay. | A notification while Shorts is open, or a browser Shorts cue, is a different interaction and requires user acceptance. |
| App-owned Chrome new-tab page on Mac | Extension New Tab override. | Documented override page; Chrome excludes new-tab replacement in incognito windows. [R02] | A new-tab surface can show private app content in its own page. It appears when a new tab opens, rather than modifying a social feed. |
| App-owned Safari new-tab page on iPhone/Mac | Safari new-tab extension override. | Apple demonstrates explicit user choice and iOS/macOS support. [R05, R06] Exact current settings and runtime behavior need device testing. | This is a documented first-party extension direction. Extension enablement/default-page choice adds onboarding. |
| Deadline cue through WhatsApp | WhatsApp Business Platform outbound message to an opted-in user. | Requires recipient opt-in and approved templates to initiate conversations or send outside the 24-hour window after the latest user message. Templates can be rejected/paused. [R08] | Treat it as an app/business-sent cue in a real WhatsApp chat. Arbitrary generated personal-note messages are not automatically approved templates. Eligibility/category and acceptance remain unverified. |
| Deadline cue through SMS | Messaging provider sends to the user's phone number. | Message creation supplies sender, recipient and content. Sending can queue/fail; delivery confirmation differs from a read receipt. [R10] Provider consent/sender/opt-out rules apply. [R12] | Provider acceptance cannot mean “you saw it.” Define failures, opt-outs and timing tolerances. Availability/registration requirements need destination-specific verification before launch. |
| Send an unattended SMS directly from the iPhone app | Standard MessageUI path is a composer. | User taps Send or Cancel. [R13] | A composer opened for user action does not deliver an unattended future cue. Provider delivery is a separate option with different privacy/cost dependencies. |

“Supported browser API” is narrower than “approved host integration.” This review does not establish X/YouTube permission, host-policy compliance, stable feed contracts or app-store approval for a specific design. Platform partnership options were not verified. No universal native feed-injection promise is justified.

## The privacy boundary changes at the surface

Encrypted synchronization protects the vault while replicated. It does not automatically protect plaintext rendered or sent elsewhere.

| Where the cue appears | What needs to be disclosed or decided |
|---|---|
| Extension-owned new-tab page | The app controls its page. Whether content and retrieval remain local still depends on actual processing and integration. No external website needs the note text merely to display this surface. |
| Note text inserted into X/YouTube webpage DOM | Content-script isolation protects JavaScript variables, while the page DOM is shared. [R01] **Inference:** ordinary DOM insertion may expose note text to the site's own scripts or other page-access components. No privacy proof or isolated embedded rendering design was tested. |
| WhatsApp cue | WhatsApp protects messages in transport and distinguishes business hosting/partners. [R09] A sender or chosen messaging processor must handle the content it sends. A plaintext note in an outgoing message therefore crosses the vault boundary. This does not imply every Meta system reads every business message. |
| SMS cue | Provider documentation explicitly describes message-body processing, logging/redaction and residual retention. Redaction restricts later access; it does not prevent initial processing. [R11] The provider/carrier delivery route is separate from encrypted vault sync. |

Possible product choices, still requiring confirmation:

- **Content cue:** “Finish the grant draft by 6pm” exposes the cue text through the selected surface/channel.
- **Generic cue:** “Your reminder is due—open your vault” limits shared text; the target app can decrypt the note after opening. Recipient/routing/timing information still exists outside the vault.
- **Selected excerpt:** the user authorizes a specific cue string or class of content for that channel. This is distinct from opting in to cloud AI.

Private-sync consent, cloud-AI consent, messaging consent and feed-rendering disclosure each govern a different boundary. Opting out of cloud AI does not by itself prevent a messaging provider from processing a reminder or a host webpage from accessing inserted text.

## “Once” needs a product definition before a delivery guarantee

Potential meanings include one item at a time, one exposure per item ever, one per day, or one attempt across every enabled surface. These yield different behavior and remain open.

If “once across all devices/channels” is intended, the PRD needs to answer:

1. Does once mean selected, rendered, visible long enough, sent, delivered, or acknowledged? SMS does not establish that a person read the message; channel read receipts can depend on settings. [R10]
2. If the phone and Mac are offline simultaneously, should one device suppress its cue or can both show it? A strict global once promise competes with immediate offline resurfacing; this is a distributed-state inference, not an OS policy.
3. If WhatsApp/SMS delivery fails, can a browser cue replace it? Does retrying consume the one chance?
4. Does an approaching deadline override the once limit, and can the user ask to see something again?
5. If the user rejects feed insertion or the platform blocks it, is another selected surface an acceptable fulfillment?

Do not equate system delivery with useful remembrance. An honest contract can expose delivery state and suppress repeats according to a confirmed rule without claiming attention was guaranteed.

## UX equivalents to confirm with the user

These are alternatives for clarification, not accepted substitutions or a scope reduction:

- Keep the X/Shorts cue as a visible app-authored insertion on supported **web** feeds, including Safari on iPhone if the user accepts browser usage.
- Keep browser new tabs as a distinct surface on both target platforms.
- Keep WhatsApp/SMS deadline cues with explicit channel permission and a choice between content and a generic vault-opening cue.
- For native iPhone X/Shorts, clarify whether an app-branded system notification is acceptable, whether web usage is acceptable, or whether native integration must remain a future platform-dependent requirement. Do not revive the rejected keyboard card.

No source-reviewed route makes all requested surfaces identical across iPhone and Mac. The product can preserve the aspiration while making each promised surface explicit about app/browser context, permissions, privacy and delivery evidence.
