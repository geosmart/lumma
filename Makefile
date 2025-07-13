codestyle:
	@echo "Formatting Dart code with 120 character line length..."
	dart format . -l 120
	@echo "Code formatting completed!"

# Alias for codestyle
format: codestyle

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

# Build the Flutter app
build:
	@echo "Building Flutter app..."
	flutter build apk
	@echo "Build completed!"


# Development workflow - format, lint, and test
dev:
	flutter run -d linux
