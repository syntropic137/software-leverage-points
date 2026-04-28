# Lens: Principles and Patterns

Cross-cutting design principles that apply across leverage points. Surface a violation when:

- **Single Responsibility:** a module/file/class touches more than one axis of change. Cite: Robert C. Martin, *Clean Architecture*; David Parnas (1972, "On the Criteria to Be Used in Decomposing Systems into Modules") for the original framing.
- **Separation of Concerns:** business logic mixed with transport, persistence, or presentation. Cite: Edsger Dijkstra (1974, "On the role of scientific thought").
- **Dependency Inversion:** high-level modules depend on low-level concrete types instead of abstractions. Cite: Martin's SOLID; Hexagonal Architecture (Alistair Cockburn).
- **Composition over Inheritance:** deep inheritance trees that should be composition graphs. Cite: GoF (1994); Brandolini's modeling guidance for inheritance abuse.
- **Loose coupling, high cohesion:** related code spread across modules; unrelated code crammed together. Cite: Constantine and Yourdon (structured design).

This lens is consulted by `software-leverage-review` during synthesis. Findings that map to it should set `lens_violations: ["principles-and-patterns"]` per the output schema.

The lens is intentionally narrow: it does NOT enforce any specific pattern (no "use the strategy pattern here"). It enforces the *principles* behind patterns. The leverage-point skills can recommend specific patterns within their domain.
