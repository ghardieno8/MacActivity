.PHONY: build release install clean run

build:
	swift build

release:
	swift build -c release

install: release
	cp .build/release/activity /usr/local/bin/activity

clean:
	swift package clean

run:
	swift run activity

top:
	swift run activity top

stats:
	swift run activity stats
