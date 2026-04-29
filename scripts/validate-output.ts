#!/usr/bin/env bun
// Minimal hand-rolled validator for the two output shapes (Stage 1 lens output and
// Stage 2 orchestrator output). Both shapes are defined in:
//   skills/software-leverage-review/slp-output-schema.yaml
//   skills/software-leverage-review/orchestrator-output-schema.yaml
// Severity, effort, and action enums mirror skills/software-leverage-review/severity-action-policy.md.
// scripts/check-policy-consistency.sh enforces parity at QA time.
//
// Usage:
//   bun scripts/validate-output.ts --file <path>            # auto-detect shape
//   bun scripts/validate-output.ts --file <path> --shape lens
//   bun scripts/validate-output.ts --file <path> --shape orchestrator
//
// Inputs may be YAML (.yaml/.yml, the production format) or JSON (.json, for legacy artifacts).

import { readFileSync } from "node:fs";
import { resolve, extname } from "node:path";

// YAML parsing for runtime outputs is TODO. The agent runtime emits YAML per the
// new policy, but the plugin has no node_modules / package.json yet, and Bun has
// no built-in YAML parser at this version. Until a `yaml` dep is added, this
// validator accepts JSON inputs (legacy artifacts) only. To validate a YAML
// output today, convert with: yq -o=json eval . input.yaml > input.json
// then run this script against the JSON.

const SEVERITIES = ["critical", "high", "medium", "low", "info"];
const EFFORTS = ["small", "medium", "large"];
const ACTIONS = ["auto-fix", "promote", "bulk"];
const LENSES = ["dry", "principles-and-patterns", "software-complexity"];
const errors: string[] = [];

function err(path: string, msg: string) { errors.push(`${path}: ${msg}`); }

function checkFinding(f: any, path: string, requireAction: boolean) {
  if (typeof f !== "object" || f === null) return err(path, "must be an object");
  const required = ["severity", "effort", "issue", "suggested_fix"];
  if (requireAction) required.push("action", "software_leverage_point");
  for (const k of required) {
    if (!(k in f)) err(path, `missing required field '${k}'`);
  }
  if ("severity" in f && !SEVERITIES.includes(f.severity)) {
    err(`${path}.severity`, `must be one of ${SEVERITIES.join(", ")} (got ${JSON.stringify(f.severity)})`);
  }
  if ("effort" in f && !EFFORTS.includes(f.effort)) {
    err(`${path}.effort`, `must be one of ${EFFORTS.join(", ")} (got ${JSON.stringify(f.effort)})`);
  }
  if ("action" in f && !ACTIONS.includes(f.action)) {
    err(`${path}.action`, `must be one of ${ACTIONS.join(", ")} (got ${JSON.stringify(f.action)})`);
  }
  if (!requireAction && "action" in f) {
    err(`${path}.action`, "lens-output (Stage 1) findings must NOT carry an 'action' field; the orchestrator computes that during Stage 2 synthesis");
  }
  if ("issue" in f && (typeof f.issue !== "string" || !f.issue)) err(`${path}.issue`, "must be non-empty string");
  if ("suggested_fix" in f && (typeof f.suggested_fix !== "string" || !f.suggested_fix)) err(`${path}.suggested_fix`, "must be non-empty string");
  if ("line" in f && (!Number.isInteger(f.line) || f.line < 0)) err(`${path}.line`, "must be non-negative integer");
  if ("lens_violations" in f) {
    if (!Array.isArray(f.lens_violations)) err(`${path}.lens_violations`, "must be array");
    else f.lens_violations.forEach((v: any, i: number) => {
      if (!LENSES.includes(v)) err(`${path}.lens_violations[${i}]`, `must be one of ${LENSES.join(", ")} (got ${JSON.stringify(v)})`);
    });
  }
}

function isLens(d: any) { return d && typeof d === "object" && "software_leverage_point" in d && "summary" in d && !("software_leverage_points_reviewed" in d); }
function isOrchestrator(d: any) { return d && typeof d === "object" && "software_leverage_points_reviewed" in d && "target" in d; }

function validateLens(doc: any) {
  for (const k of ["software_leverage_point", "findings", "summary"]) if (!(k in doc)) err("$", `missing required field '${k}'`);
  if (!Array.isArray(doc.findings)) err("$.findings", "must be array");
  else doc.findings.forEach((f: any, i: number) => checkFinding(f, `$.findings[${i}]`, false));
}

function validateOrchestrator(doc: any) {
  for (const k of ["target", "software_leverage_points_reviewed", "findings", "summary"]) if (!(k in doc)) err("$", `missing required field '${k}'`);
  if (!Array.isArray(doc.software_leverage_points_reviewed)) err("$.software_leverage_points_reviewed", "must be array");
  if (!Array.isArray(doc.findings)) err("$.findings", "must be array");
  else doc.findings.forEach((f: any, i: number) => checkFinding(f, `$.findings[${i}]`, true));
  if ("lens_synthesis" in doc) {
    if (!Array.isArray(doc.lens_synthesis)) err("$.lens_synthesis", "must be array");
    else doc.lens_synthesis.forEach((f: any, i: number) => checkFinding(f, `$.lens_synthesis[${i}]`, true));
  }
}

const args = process.argv.slice(2);
const fileIdx = args.indexOf("--file");
const shapeIdx = args.indexOf("--shape");
if (fileIdx < 0 || !args[fileIdx + 1]) {
  console.error("usage: bun scripts/validate-output.ts --file <path> [--shape lens|orchestrator]");
  process.exit(1);
}
const filePath = resolve(args[fileIdx + 1]);
const shapeFlag = shapeIdx >= 0 ? args[shapeIdx + 1] : null;
if (shapeFlag && !["lens", "orchestrator"].includes(shapeFlag)) {
  console.error(`--shape must be 'lens' or 'orchestrator' (got ${shapeFlag})`);
  process.exit(1);
}

let doc: any;
const ext = extname(filePath).toLowerCase();
if (ext === ".yaml" || ext === ".yml") {
  console.error(`YAML input parsing is not yet supported. Convert with: yq -o=json eval . ${filePath} > ${filePath}.json`);
  console.error("then run this script against the .json. (TODO: add yaml dep to support directly.)");
  process.exit(2);
}
try {
  doc = JSON.parse(readFileSync(filePath, "utf8"));
} catch (e: any) {
  console.error(`failed to read/parse ${filePath}: ${e.message}`);
  process.exit(1);
}

let shape: "lens" | "orchestrator";
if (shapeFlag === "lens") shape = "lens";
else if (shapeFlag === "orchestrator") shape = "orchestrator";
else if (isLens(doc)) shape = "lens";
else if (isOrchestrator(doc)) shape = "orchestrator";
else {
  err("$", "could not auto-detect shape; pass --shape lens|orchestrator (need 'software_leverage_point'+'summary' for lens OR 'target'+'software_leverage_points_reviewed' for orchestrator)");
  console.error(`INVALID: ${filePath}`);
  for (const m of errors) console.error(`  ${m}`);
  process.exit(1);
}

if (shape === "lens") validateLens(doc);
else validateOrchestrator(doc);

if (errors.length === 0) {
  const schemaName = shape === "lens" ? "slp-output-schema.yaml" : "orchestrator-output-schema.yaml";
  console.log(`OK: ${filePath} conforms to ${schemaName}`);
  process.exit(0);
}
console.error(`INVALID: ${filePath} (shape=${shape})`);
for (const m of errors) console.error(`  ${m}`);
process.exit(1);
