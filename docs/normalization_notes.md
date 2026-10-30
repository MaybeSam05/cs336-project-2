# Normalization rationale

The official CFPB CSV was profiled in full: 349,563 rows, 78 source columns,
and 2,135 distinct values of the assignment's ten-attribute location key.

## Applicant interpretation

Project 1 defensibly modeled Applicant as a reusable real-world person, and
points for that cardinality were restored after clarification. Project 2 does
not reuse that conceptual one-to-many relationship. The source has no stable
applicant identifier with which to recognize the same person across different
applications, and the assignment asks for only tables required by functional
dependencies.

Applicant and co-applicant scalar demographics therefore remain
application-specific foreign keys. Their repeating race values become
application-specific join rows. No invented `applicant_id` is introduced.

## BCNF and losslessness

Every lookup relation is in BCNF because its code is a key and determines its
description. `location_id` is the primary key of `location`; the complete
ten-attribute source tuple is enforced as an alternate unique key, including
the source's null-containing tuples. `application_id` is the key of
`application`. Each repeating-value relation has its complete composite key
on the left side of its only nontrivial dependency.

The decomposition is lossless because:

- every source application becomes exactly one `application` row;
- each application references exactly one ten-attribute location row;
- all code/name values are recoverable through foreign-key joins; and
- the slot number of every race and denial reason is retained.

The export pivots the join rows back into their original numbered columns and
restores the four universally null source attributes as null constants.

## Source-derived constraints

All source columns that never contain a blank are `NOT NULL` in their final
relation. Numeric values stay numeric in the application table. The only text
there is `respondent_id`, as permitted by the assignment. Census tract remains
text in `location` because it is an identifier and leading zeros matter.

Foreign keys reject nonexistent categorical codes immediately. Position
checks reject race slots outside 1-5 and denial-reason slots outside 1-3.
