# Contributing to Kelarin

Thank you for your interest in contributing to Kelarin! We welcome contributions from everyone. This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to uphold our Code of Conduct. Please report any unacceptable behavior.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/kelarin.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Set up your development environment (see README.md)

## Development Setup

```bash
# Install dependencies
flutter pub get

# Run code generation (if applicable)
flutter pub run build_runner build

# Run the app
flutter run
```

## Making Changes

### Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for automatic formatting: `dart format lib/`
- Run `flutter analyze` to check for issues
- Use meaningful variable and function names

### Commit Guidelines

We follow conventional commits for better changelog generation:

```
feat: add new focus session feature
fix: resolve timer pause issue
docs: update README with setup instructions
style: format code according to style guide
refactor: improve timer logic
test: add tests for focus timer
chore: update dependencies
```

Format: `<type>(<scope>): <subject>`

- `type`: feat, fix, docs, style, refactor, test, chore
- `scope`: optional, area of change (e.g., auth, focus, task)
- `subject`: short description in imperative mood

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/focus/focus_test.dart
```

### Pull Request Process

1. Update the README.md if you change functionality
2. Ensure all tests pass: `flutter test`
3. Run `flutter analyze` and fix any issues
4. Update documentation for new features
5. Create a descriptive PR title and description
6. Request review from maintainers

**PR Description Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Fixes #(issue number)

## Testing
Describe testing performed

## Screenshots (if applicable)
Add screenshots for UI changes
```

## Reporting Issues

### Bug Report Template

```markdown
## Description
Clear description of the bug

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Flutter version: `flutter --version`
- Device: Android/iOS
- App version: X.X.X
```

### Feature Request Template

```markdown
## Description
Clear description of the feature

## Problem Statement
Why is this feature needed?

## Proposed Solution
How should this be implemented?

## Alternatives Considered
Other approaches tried or considered
```

## Project Structure

```
lib/
├── core/              # Shared utilities, constants, themes
├── features/          # Feature modules
│   ├── auth/         # Authentication
│   ├── focus/        # Focus timer
│   ├── task/         # Task management
│   └── ...
├── shared/           # Shared widgets and utilities
└── main.dart        # Entry point
```

## Development Tips

- Use `flutter run -v` for verbose output during debugging
- Use `DevTools` for performance profiling: `flutter pub global run devtools`
- Check the [Flutter docs](https://docs.flutter.dev/) for framework features
- Review [Riverpod docs](https://riverpod.dev/) for state management patterns

## Questions?

- Check existing issues and discussions
- Ask in the GitHub Discussions section
- Contact maintainers through issues

## Recognition

Contributors will be recognized in the README.md. Thank you for helping improve Kelarin!

---

Happy coding! 🚀
