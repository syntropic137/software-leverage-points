# Lens: DRY (Don't Repeat Yourself)

DRY is a cross-cutting principle. Surface a violation when:

- The same logic appears in 3+ places without justification
- Constants are inlined instead of named
- Configuration values are duplicated across files
- Test fixtures are copy-pasted rather than factored

DRY is NOT a license to:
- Force premature abstraction (rule of three)
- Couple unrelated modules to share trivial code
- Introduce indirection that hurts readability

When invoked from a software leverage point review, return `lens_violations: ["dry"]` on relevant findings.
