# Triage labels

| Role | Local label | Meaning |
| --- | --- | --- |
| needs-triage | needs-triage | Requires evaluation |
| needs-info | needs-info | Waiting for information or a decision |
| ready-for-agent | ready-for-agent | Specified and unblocked |
| ready-for-human | ready-for-human | Requires human action |
| wontfix | wontfix | Will not be actioned |

Implementation lifecycle additionally uses claimed and resolved. A dependency-blocked ticket records its blocking edges and remains needs-info until those edges resolve. Do not triage tickets produced by to-tickets again.
