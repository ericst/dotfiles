# Claude Code Configuration

This file provides guidance to Claude Code when working on projects.

## Git Commit Guidelines

- Do not add attribution in git commit messages
- Keep commit messages concise and descriptive
- Focus on what changed and why, not how

## OpenCode Configuration

- Never add "🤖 Generated with [opencode](https://opencode.ai)" to git commits
- Never add "Co-Authored-By: opencode <noreply@opencode.ai>" to git commits
- The AGENTS.md file presence is sufficient attribution

## General Development Practices

- Always read existing code patterns before making changes
- Follow the existing code style and conventions
- Use existing libraries and utilities when available
- Never assume a library is available without checking first

## Project Context

- Check for package.json, Cargo.toml, or similar files to understand dependencies
- Look at neighboring files to understand project structure
- Examine imports and existing patterns before writing new code

## Code Quality

- Follow security best practices
- Never expose or log secrets and keys
- Never commit sensitive information to repositories
- Write tests when appropriate and use existing test frameworks

## Communication

- Be concise and direct in responses
- Avoid unnecessary explanations unless requested
- Focus on the specific task at hand
- Minimize output while maintaining quality

## File Operations

- Prefer editing existing files over creating new ones
- Only create new files when explicitly required
- Never proactively create documentation files unless requested
- Use absolute paths for file operations

## Error Handling

- Run linting and type checking commands when available
- Test changes thoroughly before completion
- Handle errors gracefully and provide clear feedback

## About Me
- My name is Eric Seuret
- My personal e-mail address is eric@ericst.ch
- My professional e-mail address is eric.seuret@cylenk.com
