# GitHub Upload Checklist

Use this checklist to ensure your project is ready for GitHub upload.

## Before You Push

### Code Quality
- [ ] Run `flutter analyze` - no errors or warnings
- [ ] Run `dart format lib/` - all code properly formatted
- [ ] Run `flutter test` - all tests passing
- [ ] Code follows project style guide
- [ ] No commented-out code blocks
- [ ] No debug print statements
- [ ] No hardcoded values or secrets

### Security & Sensitive Files
- [ ] ✅ `.gitignore` properly configured
- [ ] ✅ `google-services.json` NOT committed
- [ ] ✅ `local.properties` NOT committed
- [ ] ✅ `.env` files NOT committed
- [ ] ✅ API keys NOT in code
- [ ] ✅ Private credentials NOT in code
- [ ] No passwords or tokens in strings
- [ ] No personal information in comments

### Documentation
- [ ] ✅ `README.md` updated with project details
- [ ] ✅ `CONTRIBUTING.md` created
- [ ] ✅ `CODE_OF_CONDUCT.md` created
- [ ] ✅ `LICENSE` file added
- [ ] ✅ `FIREBASE_SETUP.md` created
- [ ] API documentation in comments (if needed)
- [ ] Setup instructions are clear
- [ ] Installation steps are tested

### Project Files
- [ ] ✅ `.gitattributes` created
- [ ] ✅ `.github/` directory with templates
- [ ] ✅ Issue templates in `.github/ISSUE_TEMPLATE/`
- [ ] ✅ Pull request template created
- [ ] ✅ GitHub Actions workflow created
- [ ] `pubspec.yaml` complete with description
- [ ] `pubspec.lock` exists

### Git Configuration
- [ ] Run `git config user.name "Your Name"`
- [ ] Run `git config user.email "your.email@example.com"`
- [ ] Initial commit is meaningful
- [ ] Commit history is clean
- [ ] No accidentally committed build artifacts

## Upload Steps

### 1. Create GitHub Repository
```bash
# Create repo on GitHub (via web browser)
# Copy the new repo URL
```

### 2. Add Remote
```bash
cd kelarin
git remote add origin https://github.com/yourusername/kelarin.git
```

### 3. Rename Branch (if needed)
```bash
git branch -M main
```

### 4. Push Code
```bash
git push -u origin main
```

### 5. Verify on GitHub
- [ ] Code appears correctly
- [ ] Files are visible
- [ ] README renders properly
- [ ] No sensitive files visible
- [ ] All branches pushed correctly

## Post-Upload

### On GitHub
- [ ] ✅ Update repo description in settings
- [ ] ✅ Add relevant topics/tags
- [ ] ✅ Configure branch protection rules
- [ ] ✅ Enable discussions (optional)
- [ ] ✅ Set up issues & PRs settings
- [ ] Consider enabling GitHub Pages (optional)

### Additional Security
- [ ] Enable branch protection for main
- [ ] Require pull request reviews
- [ ] Enable status checks before merge
- [ ] Add CODEOWNERS file (optional)

## Important Notes

⚠️ **Once pushed to GitHub, history is permanent. Double-check:**
- No sensitive information is committed
- No build artifacts or large files
- No personal credentials anywhere
- All important code is included

## Troubleshooting

### Accidentally pushed secrets?
1. Do NOT just delete and recommit
2. Use: `git filter-branch` or `git filter-repo`
3. Or rotate/revoke the exposed credentials
4. Force push: `git push --force-with-lease`

### Large files in history?
1. Install BFG Repo-Cleaner
2. Clean history: `bfg --strip-blobs-bigger-than 100M`
3. Force push: `git push --force-with-lease`

### README not rendering?
- Check for syntax errors in Markdown
- Ensure file is named exactly `README.md`
- Verify special characters are escaped

## Final Verification Script

```bash
# Run this before pushing
echo "=== Code Quality ==="
flutter analyze lib/
dart format --set-exit-if-changed lib/
flutter test

echo "=== Git Status ==="
git status

echo "=== Checking for secrets ==="
git diff --cached | grep -i 'password\|api_key\|secret\|token' || echo "No obvious secrets found"

echo "=== Ready to push? ==="
```

## Checklist Summary

Once ALL items are checked:
1. ✅ Code quality verified
2. ✅ Security reviewed
3. ✅ Documentation complete
4. ✅ Git configured
5. ✅ Repository created on GitHub
6. ✅ Ready to push!

```bash
git push -u origin main
```

---

**Last Updated**: May 2026
**Version**: 1.0
