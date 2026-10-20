# Local Markdown tracker

One feature lives in `.scratch/<feature>/`, with `spec.md` and separate numbered `issues/NN-slug.md` files. Native implementation uses `.scratch/native-mvp/`. Keep the earlier product/wayfinding tracker intact.

Each ticket records Status and Blocked by near the top, acceptance criteria in its body and conversation under Comments. Publishing means writing these files. Fetching means reading the referenced file. Claim an unblocked ready-for-agent ticket by setting Status to claimed before work; resolve only after acceptance evidence and review. Do not resolve a parent product issue automatically.

Blocking edges reference tickets within the same feature plus named external decisions/prerequisites. A ticket is ready only when its actual blockers are resolved. Preserve historical claimed/resolved conventions in the earlier tracker. There is no hosted-issue migration.
