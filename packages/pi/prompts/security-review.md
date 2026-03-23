---
description: Perform a focused security review for vulnerabilities
---
Perform a security-focused review of the specified code. Do not modify any files —
review only.

$@

If a scope was provided above, restrict your review accordingly. Otherwise review
the entire codebase.

## Objective

Identify **high-confidence** security vulnerabilities with real exploitation
potential. This is not a general code review — focus only on security implications.

## Severity Levels

| Level | Meaning |
|-------|---------|
| **HIGH** | Directly exploitable: RCE, data breach, auth bypass |
| **MEDIUM** | Exploitable under specific conditions, significant impact |
| **LOW** | Defense-in-depth issues, lower-impact findings |

Only report HIGH and MEDIUM findings. Do not flood the report with noise.

## Confidence Threshold

Only report findings where you are ≥80% confident of actual exploitability.

| Score | Confidence |
|-------|------------|
| 0.9–1.0 | Certain exploit path, known exploitation methods |
| 0.8–0.9 | Clear vulnerability pattern with known exploitation |
| 0.7–0.8 | Suspicious pattern, requires specific conditions |
| <0.7 | Do not report — too speculative |

## Categories to Examine

**Input Validation**
- SQL injection via unsanitized user input
- Command injection in system calls or subprocesses
- Path traversal in file operations
- NoSQL injection, template injection, XXE

**Authentication & Authorization**
- Authentication bypass logic
- Privilege escalation paths
- Session management flaws
- Authorization logic bypasses

**Crypto & Secrets**
- Hardcoded API keys, passwords, or tokens
- Weak cryptographic algorithms
- Improper key storage

**Injection & Code Execution**
- XSS vulnerabilities (web apps)
- Deserialization vulnerabilities
- Eval injection, pickle injection

**Data Exposure**
- Sensitive data logging
- PII handling violations
- API endpoint data leakage

## Hard Exclusions

Do **not** report:

1. Denial of Service vulnerabilities
2. Rate limiting concerns
3. Secrets stored on disk (handled elsewhere)
4. Memory safety issues in safe languages (Rust, Go, etc.)
5. Theoretical issues without a clear attack path
6. Missing audit logs
7. Log spoofing concerns
8. Documentation issues
9. Test file vulnerabilities
10. Regex injection or ReDoS

## Precedence Rules

Some patterns are safe by default:

1. Logging URLs is assumed safe
2. UUIDs are unguessable — no need to validate
3. Environment variables and CLI flags are trusted values
4. React/Angular XSS only if using `dangerouslySetInnerHTML` or similar
5. Client-side auth checks are not required — server is responsible
6. Shell script command injection only if untrusted input flows in

## Review Process

1. Identify existing security patterns in the codebase (sanitization, validation)
2. Compare changes against established patterns
3. Trace data flow from user inputs to sensitive operations
4. Identify injection points and unsafe operations
5. Assign confidence score to each finding
6. Filter by confidence threshold

## Output Format

```markdown
## Vulnerability 1: <Title>
- **File**: `path/to/file:line`
- **Severity**: HIGH | MEDIUM
- **Category**: sql_injection | xss | auth_bypass | etc.
- **Confidence**: 0.8–1.0
- **Description**: What the issue is
- **Exploit Scenario**: How an attacker could exploit this
- **Recommendation**: How to fix it
```

## Summary

End with a count of HIGH, MEDIUM, and LOW findings. If no vulnerabilities are found,
state that clearly.

## Rules

- Do not use bash or write to any files
- Only report findings with confidence ≥0.8
- Be specific — include file paths and line numbers
- Do not modify any files
