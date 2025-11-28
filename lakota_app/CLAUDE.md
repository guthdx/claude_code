# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Lakota language learning and translation system that integrates three core resources:

1. **English-Lakota Dictionary** (`docs/309415410-english-lakota-dictionary.txt`) - 1,019 lines
   - Alphabetically organized English-to-Lakota translations
   - Includes pronunciation guides in parentheses format: `word - translation (pronunciation)`
   - Contains verb conjugation patterns (1st, 2nd, 3rd class verbs)
   - Grammar notes and parts of speech markers

2. **Lakota Pronunciation Glossary** (`docs/Lakota Pronunciation Glossary.txt`) - 3,444 lines
   - Comprehensive bidirectional Lakota↔English glossary
   - Detailed phonetic breakdowns
   - Cultural and ceremonial terminology
   - Format: `LAKOTA/Meaning/pronunciation-guide`

3. **12 Essential Sentences** (`docs/12_essential_sentences.rtf`) - 21 lines
   - Basic sentence structures for context and grammar patterns
   - Designed for translation practice and language usage examples

## Architecture Principles

The system should be designed with three integrated layers:

### 1. Dictionary Layer
- Parse and structure the English-Lakota dictionary
- Handle word lookups, parts of speech, and grammatical markers
- Support verb conjugation (1st/2nd/3rd class patterns documented at end of dictionary)

### 2. Phonetics Layer
- Process pronunciation guides from both glossary sources
- Handle Lakota phonetic notation (special characters: á, č, ġ, ḣ, ǩ, ṗ, š, ṫ, ž, ŋ)
- Map between different pronunciation guide formats in the two source files

### 3. Context/Grammar Layer
- Use the 12 essential sentences as training/validation data
- Extract grammatical patterns and sentence structures
- Support sentence construction and translation validation

## Data Format Notes

### Dictionary Format
- Entries: `english_word - n./v./adj. lakota_translation (pronunciation) notes`
- Verb classes marked: `1st cl.`, `2nd cl.`, `3rd cl.`
- Pronunciation separates syllables with hyphens
- Multiple definitions numbered: `1.`, `2.`, `3.`

### Glossary Format
- Entries: `LAKOTA WORD/English meaning/pronunciation`
- All caps for Lakota terms
- Forward slashes as delimiters

### Special Considerations
- The `/` character in verbs indicates where conjugation occurs (e.g., `má/ni` → `mawani`, `mauŋnipi`)
- Bracketed `[y]` in 2nd class verbs shows replaceable character
- Enclitics and suffixes marked with `-` or special notation
- Gender-specific terms marked with `male` or `fem.` tags
