# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This folder is a **shared template library** for bootstrapping new projects. It is NOT an application - it contains templates, strategy documents, and user preferences that are consumed by the `wowasi_ya` tool (sibling folder) to generate new project documentation.

## Key Files

| File | Purpose |
|------|---------|
| `project_starter_kit.md.rtf` | Defines the 15-document folder structure template |
| `project_starter_kit_prompt.md.rtf` | Prompt template for generating all 15 docs from a project description |
| `claude_code_agent_strategy.md` | **Core logic** - defines how to analyze projects and generate dynamic research agents |
| `user_context_g3dx.md.rtf` | User preferences, constraints, and interaction style |

## Agent Strategy Overview

The `claude_code_agent_strategy.md` defines a 4-phase workflow:

1. **Phase 0: Agent Discovery** - Analyze project description, generate ad hoc research agents based on detected domains/stakeholders
2. **Phase 1: Research** - Execute agents to gather context (regulations, grants, best practices)
3. **Phase 2: Document Generation** - Generate 15 starter kit documents in batches
4. **Phase 3: Quality Check** - Cross-reference validation

### Domain Keyword Map
Projects are analyzed for keywords in: healthcare, finance, technology, agriculture, education, infrastructure, governance, community, environment

### Key Concepts
- **Ad hoc agents**: Dynamically generated research agents tailored to project context
- **Intersection rules**: When domains overlap (e.g., healthcare + community), specialized hybrid agents are created
- **Stakeholder triggers**: Mentions of elders, tribal council, researchers, etc. spawn relevant agents

## User Context

The user works in **tribal, rural, and sovereignty-focused contexts** with these key constraints:

- Data sovereignty: PHI/PII must be handled carefully, prefer local storage
- Infrastructure: pfSense, Proxmox, AD DS, VLANs, VPNs, Cloudflare
- Domains: health research, nonprofits, agriculture, finance, infrastructure
- Preference: Recommend **best solutions** even if unfamiliar, not just safe/known options
- Air-gapped/on-prem environments common

## Related Projects

- `../wowasi_ya/` - The tool that implements this strategy (Lakota for "assistant")

## Do NOT

- Modify templates without understanding downstream impact on wowasi_ya
- Assume this folder contains runnable code - it's documentation/configuration only
- Remove RTF files - they're the source format for the templates
