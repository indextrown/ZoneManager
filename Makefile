.PHONY: analyze test run check-run

analyze:
	flutter analyze

test:
	flutter test

run:
	flutter run

check-run: analyze test run
