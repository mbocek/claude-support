---
allowed-tools: Bash(ls:*), Read, Write
description: Sync IntelliJ IDEA modules.xml with project subdirectories
---

## Context

- Project root: !`pwd`
- Existing modules.xml: !`cat .idea/modules.xml 2>/dev/null || echo "not found"`
- Subdirectories with code: !`ls -d */ | grep -v -E '^\.(idea|claude|git)|^artifacts|^scratchpad' | sed 's/\/$//'`

## Your task

Scan the project root for subdirectories that should be IntelliJ modules (skip `.idea`, `.claude`, `.git`, `artifacts`, `scratchpad`). For each directory, ensure:

1. A `.iml` module file exists in `.idea/<dir-name>.iml` — create if missing with a basic Web module type
2. The module is registered in `.idea/modules.xml`

IML template for new modules:
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
