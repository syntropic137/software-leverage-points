# Lens: Software Complexity

Complexity is the dominant force that makes software hard to change. This lens surfaces complexity that is "essential" or "accidental" in Brooks's sense, and pushes toward reduction.

Surface a finding when:

- **Cognitive load is unjustified:** a function/class requires more concepts in working memory than the task warrants. Cite: John Ousterhout, *A Philosophy of Software Design* (deep modules over shallow ones; "complexity is anything related to the structure of a software system that makes it hard to understand and modify").
- **Cyclomatic / cognitive complexity is high without a reason:** branchy code without an extracted abstraction. Cite: Sonar's cognitive-complexity metric; McCabe (1976) for the cyclomatic original.
- **Accidental coupling:** two modules co-vary because of an arbitrary shared assumption, not a real dependency. Cite: Brooks (1986, "No Silver Bullet"); Pragmatic Programmer (Hunt and Thomas) on orthogonality.
- **Premature abstraction:** an abstraction added without three concrete cases driving it. Cite: "rule of three" (Refactoring, Fowler).
- **Asymmetric simplicity:** the abstraction makes the common case harder so the rare case is easier. Cite: Ousterhout on "make the common case fast and obvious".

This lens is consulted by `software-leverage-review` during synthesis. Findings set `lens_violations: ["software-complexity"]`.

The lens is NOT a complexity-metric absolutist. A high-cyclomatic-complexity function with a clear single purpose may be the right call. The lens asks: is the complexity *paying its way*?
