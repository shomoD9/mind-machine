# Capture, refinding, and maintenance: research implications

Research date: 2026-10-19. Source review; no user study or product benchmark was conducted.

Low capture effort, contextual retrieval, and visibility deserve separate tests. Storing more information does not establish that someone can find it or use it later. These are design implications from the sources below, rather than a measured result for this proposed app.

## Primary sources

### R01 — Information scraps

Source: Michael Bernstein, Max Van Kleek, MC Schraefel, David Karger, [Management of Personal Information Scraps](https://publications.csail.mit.edu/abstracts/abstracts07/bernstein/bernstein.html), MIT CSAIL research abstract, 2007.

The researchers describe small personal records that fit poorly into structured applications: half-formed thoughts, reminders, references, and messages to oneself. They investigate lightweight capture, automatically retained context, and integration with existing applications. Their proposed appointment workflow keeps the original freeform note and synchronizes structured information with approval.

Evidence limit: this page describes a research program and an informal diary exercise. It establishes relevant prior design work; it does not validate a modern AI organizer, market demand, or a keyboard extension.

### R02 — Refinding with context

Source: Susan Dumais and colleagues, [Stuff I've Seen: A System for Personal Information Retrieval and Re-Use](https://www.microsoft.com/en-us/research/publication/stuff-ive-seen-a-system-for-personal-information-retrieval-and-re-use/), SIGIR 2003.

The system indexed several information forms together and used contextual cues to help people locate previously encountered information. The publication summary reports internal use by more than 230 employees and identifies time and people as useful cues.

Evidence limit: an older workplace study and prototype. It supports testing contextual clues alongside content similarity; it does not establish the best ranking method for this personal vault.

### R03 — Why information strategies are abandoned

Source: Elisabeth Jones, Harry Bruce, Predrag Klasnja, William Jones, [I give up! Five factors that contribute to the abandonment of information management strategies](https://asistdl.onlinelibrary.wiley.com/doi/full/10.1002/meet.2008.14504503115), proceedings volume 2008; publisher lists first online publication as 3 June 2009.

In interviews with 22 people, 14 described at least one abandoned information-management strategy; the researchers identified 33 episodes. Their themes were visibility, integration, co-adoption, scalability, and return on investment. Participants described forgetting systems they could not keep visible and finding value when information tools connected to routines already in use.

Evidence limit: a small qualitative sample with many students; the study was not designed to estimate second-brain abandonment rates. It cannot justify the claim that nobody uses second brains successfully.

### R04 — A limit on the memory metaphor

Source: Abigail Sellen and Steve Whittaker, [Beyond Total Capture: A Constructive Critique of Lifelogging](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/p70-sellen.pdf), Communications of the ACM, May 2010.

The authors argue that personal archives should be designed around specific uses and human memory processes. They question whether comprehensive recording, by itself, delivers useful remembering.

Evidence limit: a critique of lifelogging, rather than an experiment on deliberate note capture. The proposed app involves user-submitted material; its scope should not silently expand to recording everything a person types or sees.

## Requirements proposed from the evidence

These proposals need user confirmation or product testing. None is a finding that a source tested this product.

| Proposal | Reason | How to test |
| --- | --- | --- |
| Save a mixed capture without title, folder, or type selection. | Low-value records should not incur a filing decision before they exist. R01, R03. | Compare thought-to-save effort against the person's self-chat workflow. |
| Search using exact strings, concepts, dates, people, and source clues. | A person may remember context more clearly than wording. R02. | Use held-out queries written before showing the original captures. |
| Preserve the original and its origin separately from model interpretation. | Later use depends on being able to judge what was actually recorded. R01 informs this choice; source preservation is also an existing project commitment. | Follow each result and answer back to the full original. |
| Make everyday access available where the person already works. | Integration and visibility recur in abandonment accounts. R03. | Observe return after a week without requiring visits to a separate dashboard. |
| Decide resurfacing independently of explicit search. | Search begins with a request. Forgotten intentions or resources may never receive a query. This is a product inference supported by the visibility problem in R03. | Evaluate useful spontaneous returns and unwanted interruptions separately. |
| Evaluate reuse and trust alongside capture volume. | A larger archive alone is an incomplete outcome. R04 motivates this test. | Track successful find/copy/open/insert outcomes and perceived confidence. |

## Challenges for the product vision

1. **“No one ends up using a second brain” exceeds the evidence.** There are failure reports, working systems, and different goals. The target should be people whose upkeep and retrieval costs outweigh their benefit.
2. **“Self-organizes” needs an observable result.** The user should be able to find a screenshot from an approximate description, open its original, and correct an incorrect inference. Automatically creating tags or a graph does not prove this.
3. **An unsearched note can stay buried.** Explicit search and system-initiated resurfacing address different situations. Whether the latter belongs in the product is still a user decision.
4. **A memory and a commitment have different consequences.** Keeping the sentence “pay the bill Friday” is useful; guaranteeing a reminder adds delivery, time-zone, permission, and failure-handling responsibilities. This boundary is open.
5. **Replacing a keyboard adds a new adoption cost.** The product must beat opening a familiar self-chat and must preserve everyday typing. Keyboard selection, Full Access, and language support belong in the usability test.

## What remains unproven

Willingness to replace or augment a keyboard, willingness to pay, retention, search quality on real private material, acceptable interruption frequency, voice/OCR quality across the person's languages, cloud-processing tolerance, and whether a new vault beats integration with existing stores. Public discussions and vendor documentation cannot settle those questions.
