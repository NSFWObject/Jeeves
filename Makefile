carthage install:
	carthage update --use-submodule

test:
	xcodebuild test -scheme Jeeves | xcpretty