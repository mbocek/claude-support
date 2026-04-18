---
allowed-tools: Bash(ls:*), Bash(pwd), Read, Write, Glob
description: Sync IntelliJ IDEA modules.xml with project subdirectories
---

## Context

- Current working directory: !`pwd`

## Your task

1. **Locate the IntelliJ project root.** Starting from the working directory, walk up the tree until a directory contains a `.idea/` subdirectory. Use the Glob tool with `pattern=".idea/modules.xml"` (or `".idea"` wildcard) and `path=<candidate>` — or `Bash: ls <candidate>/.idea` — to test. If no `.idea/` is found before you reach `$HOME` or `/`, stop and print a short message telling the user to run from the IntelliJ project root. Do not create any files.
2. From the project root:
   - Read `.idea/modules.xml` with the Read tool (treat as "not found" if it doesn't exist).
   - List immediate subdirectories with `Bash: ls -d <root>/*/`.
   - Find Go modules with the Glob tool: `pattern="*/go.mod"`, `path=<root>`. Each match `<dir>/go.mod` means `<dir>` is a Go module.
3. Scan the subdirectories for candidate IntelliJ modules (skip `.idea`, `.claude`, `.git`, `artifacts`, `scratchpad`, and any other dotfile directories). For each kept directory, ensure:
   - `<root>/.idea/<dir-name>.iml` exists AND contains a `<component name="NewModuleRootManager">` with `<content url="file://$MODULE_DIR$/<dir-name>">`. If missing OR the content is wrong (e.g., stub with only `AdditionalModuleElements`, missing `NewModuleRootManager`, wrong path), overwrite it with the template below.
   - The module is registered in `<root>/.idea/modules.xml`

Pick the template based on whether `<dir-name>/go.mod` exists.

**Go module template** (when `<dir-name>/go.mod` exists):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<module type="WEB_MODULE" version="4">
  <component name="Go" enabled="true" />
  <component name="NewModuleRootManager" inherit-compiler-output="true">
    <exclude-output />
    <content url="file://$MODULE_DIR$/<dir-name>">
      <excludeFolder url="file://$MODULE_DIR$/<dir-name>/vendor" />
      <excludeFolder url="file://$MODULE_DIR$/<dir-name>/bin" />
    </content>
    <orderEntry type="inheritedJdk" />
    <orderEntry type="sourceFolder" forTests="false" />
  </component>
</module>
```

**Web module template** (fallback for non-Go directories):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<module type="WEB_MODULE" version="4">
  <component name="NewModuleRootManager" inherit-compiler-output="true">
    <exclude-output />
    <content url="file://$MODULE_DIR$/<dir-name>" />
    <orderEntry type="inheritedJdk" />
    <orderEntry type="sourceFolder" forTests="false" />
  </component>
</module>
```

Update `.idea/modules.xml` to include all modules. Remove entries for directories that no longer exist.

Do not send any other text or messages besides the tool calls.
