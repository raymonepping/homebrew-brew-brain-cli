# brew_brain 🌳

> "Structure isn't boring – it's your first line of clarity." — *You (probably during a cleanup)*

[![brew install](https://img.shields.io/badge/brew--install-success-green?logo=homebrew)](https://github.com/raymonepping/homebrew-brew_brain)
[![version](https://img.shields.io/badge/version-1.4.0-blue)](https://github.com/raymonepping/homebrew-brew_brain)

---

## 🚀 Quickstart

```bash
brew tap 
brew install /brew_brain
brew_brain
```

---


## 📂 Project Structure

```
./
├── bin/
│   ├── brew_brain*
│   └── CHANGELOG_brew_brain.md*
├── Formula/
│   └── brew-brain-cli.rb
├── lib/
│   ├── brew_brain_dump.sh*
│   └── brew_brain_functions.sh*
├── tpl/
│   ├── brew_brain_footer.tpl
│   ├── brew_brain_header.tpl
│   ├── brew_brain_md.tpl
│   ├── brew_brain_status.tpl
│   ├── brew_brain_summary.tpl
│   ├── readme_01_header.tpl
│   ├── readme_02_project.tpl
│   ├── readme_03_structure.tpl
│   ├── readme_04_body.tpl
│   ├── readme_05_quote.tpl
│   ├── readme_06_article.tpl
│   └── readme_07_footer.tpl
├── .backup.yaml
├── .backupignore
├── .version
├── FOLDER_TREE.md
├── my_brews.json
├── reload_version.sh*
└── sanity_check.md

5 directories, 24 files
```

---

## 🧭 What Is This?

brew_brain is a Homebrew-installable, wizard-powered CLI that helps you audit, document, and keep your Homebrew setup under control. It’s especially useful for:

- Developers and DevOps engineers managing lots of local tools
- Sharing your Homebrew arsenal with your team (or just bragging)
- Keeping an audit log of installed tools, versions, and upgrades

---

## 🔑 Key Features

- Instantly audit your installed Homebrew formulas and casks
- Generate Markdown reports with version badges
- Spot outdated, missing, or duplicate tools
- Export your arsenal for documentation or sharing
- Designed for easy scripting and CI/CD integration

---

### Auto-generate a Homebrew audit report

```bash
brew_brain
```

---

### ✨ Other CLI tooling available

✅ **brew-brain-cli**  
CLI toolkit to audit, document, and manage your Homebrew CLI arsenal with one meta-tool

✅ **bump-version-cli**  
CLI toolkit to bump semantic versions in Bash scripts and update changelogs

✅ **commit-gh-cli**  
CLI toolkit to commit, tag, and push changes to GitHub

✅ **folder-tree-cli**  
CLI toolkit to visualize folder structures with Markdown reports

✅ **radar-love-cli**  
CLI toolkit to simulate secret leaks and trigger GitHub PR scans

✅ **repository-audit-cli**  
CLI toolkit to audit Git repositories and folders, outputting Markdown/CSV/JSON reports

✅ **repository-backup-cli**  
CLI toolkit to back up GitHub repositories with tagging, ignore rules, and recovery

✅ **repository-export-cli**  
CLI toolkit to export, document, and manage your GitHub repositories from the CLI

✅ **self-doc-gen-cli**  
CLI toolkit for self-documenting CLI generation with Markdown templates and folder visualization

---

## 🧠 Philosophy

brew_brain 

> Some might say that sunshine follows thunder  
> Go and tell it to the man who cannot shine  
>
> Some might say that we should never ponder  
> On our thoughts today ‘cos they hold sway over time

<!-- — Oasis, "Some Might Say" -->

---

## 📘 Read the Full Medium.com article

📖 [Article](..) 

---

© 2025 Your Name  
🧠 Powered by self_docs.sh — 🌐 Works locally, CI/CD, and via Brew
