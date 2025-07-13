codestyle:
	@echo "Formatting Dart code with 120 character line length..."
	dart format . -l 120
	@echo "Removing unused imports..."
	dart fix --apply
	@echo "Code formatting and cleanup completed!"

# Run static analysis
lint:
	@echo "Running Dart analyzer..."
	dart analyze
	@echo "Static analysis completed!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	flutter clean
	@echo "Clean completed!"

dev:
	flutter build apk --release
