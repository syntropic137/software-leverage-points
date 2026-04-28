#!/usr/bin/env bun
// Minimal hand-rolled validator for skills/software-leverage-review/output-schema.json.
// Covers required-field and enum checks for both per-LP and merged orchestrator shapes.
// Run from repo root: bun scripts/validate-output.ts --file path/to/output.json

import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const SEVERITIES = ["error", "warn", "info"];
const LENSES = ["dry", "principles-and-patterns", "software-complexity"];
const errors: string[] = [];

function err(path: string, msg: string) { errors.push(`${path}: ${msg}`); }

function checkFinding(f: any, path: string) {
  if (typeof f !== "object" || f === null) return err(path, "must be an object");
  for (const k of ["severity", "issue", "suggested_fix"]) {
    if (!(k in f)) err(path, `missing required field '${k}'`);
  }
  if ("severity" in f && !SEVERITIES.includes(f.severity)) {
    err(`${path}.severity`, `must be one of ${SEVERITIES.join(", ")} (got ${JSON.stringify(f.severity)})`);
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

function isPerLP(d: any) { return d && typeof d === "object" && "software_leverage_point" in d && "summary" in d && !("software_leverage_points_reviewed" in d); }
function isMerged(d: any) { return d && typeof d === "object" && "software_leverage_points_reviewed" in d && "target" in d; }

function validate(doc: any) {
  if (isPerLP(doc)) {
    for (const k of ["software_leverage_point", "findings", "summary"]) if (!(k in doc)) err("$", `missing required field '${k}'`);
    if (!Array.isArray(doc.findings)) err("$.findings", "must be array"); else doc.findings.forEach((f: any, i: number) => checkFinding(f, `$.findings[${i}]`));
  } else if (isMerged(doc)) {
    for (const k of ["target", "software_leverage_points_reviewed", "findings", "summary"]) if (!(k in doc)) err("$", `missing required field '${k}'`);
    if (!Array.isArray(doc.software_leverage_points_reviewed)) err("$.software_leverage_points_reviewed", "must be array");
    if (!Array.isArray(doc.findings)) err("$.findings", "must be array"); else doc.findings.forEach((f: any, i: number) => checkFinding(f, `$.findings[${i}]`));
    if ("lens_synthesis" in doc) {
      if (!Array.isArray(doc.lens_synthesis)) err("$.lens_synthesis", "must be array");
      else doc.lens_synthesis.forEach((f: any, i: number) => checkFinding(f, `$.lens_synthesis[${i}]`));
    }
  } else {
    err("$", "does not match per-LP or merged orchestrator shape (need 'software_leverage_point'+'summary' OR 'target'+'software_leverage_points_reviewed')");
  }
}

const args = process.argv.slice(2);
const idx = args.indexOf("--file");
if (idx < 0 || !args[idx + 1]) { console.error("usage: bun scripts/validate-output.ts --file <path>"); process.exit(1); }
const filePath = resolve(args[idx + 1]);
let doc: any;
try { doc = JSON.parse(readFileSync(filePath, "utf8")); } catch (e: any) { console.error(`failed to read/parse ${filePath}: ${e.message}`); process.exit(1); }
validate(doc);
if (errors.length === 0) { console.log(`OK: ${filePath} conforms to output-schema.json`); process.exit(0); }
console.error(`INVALID: ${filePath}`); for (const m of errors) console.error(`  ${m}`); process.exit(1);
