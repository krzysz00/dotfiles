---
name: run-llvm-tests
description: Builds and runs LLVM/MLIR/Clang tests. Use when you need to verify changes to the LLVM project by running relevant test suites.
---

# Run Tests (LLVM)

Build all the required targets and run tests.

## Steps

1. **Find the build directory and `cd` to it**
  - This will usually be `WORKSPACE_ROOT/build`

2. **Identify the relevant subproject to test**
  - Explore the codebase looking for relevant tests
  - For mlir, run `ninja check-mlir`
    * For more specific components, append the component path test target, e.g.,: `ninja check-mlir-dialect-spirv`
  - For LLVM, run `ninja check-llvm`
    * For more specific components, use the `LIT_FILTER`environment variable with env, e.g.: `env LIT_FILTER=AMDGPU ninja check-llvm`

3. Make sure that all test targets are actually built -- use `ninja`.

4. **Summarize results**
  - How many tests were discovered. If none, the test invocation was most likely wrong.
  - How many passed / failed / were disabled

5. **Analyze failures (if any)**
    - Categorize by type: pre-existing / unrelated, new failures
    - Generate a repro command that runs the failing tests only
