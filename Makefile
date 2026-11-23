.PHONY: all build build-release install run clean project open

all: build

project:
	xcodegen generate

build:
	xcodebuild -project YAN.xcodeproj -scheme YAN -configuration Debug build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""

build-release:
	xcodebuild -project YAN.xcodeproj -scheme YAN -configuration Release build CODE_SIGN_IDENTITY="-"

install: build-release
	@killall YAN 2>/dev/null || true
	rm -rf /Applications/YAN.app
	cp -R "$$(find ~/Library/Developer/Xcode/DerivedData/YAN-*/Build/Products/Release/YAN.app -maxdepth 0 2>/dev/null | head -n 1)" /Applications/
	codesign --force --deep --sign - /Applications/YAN.app
	open /Applications/YAN.app

open:
	open YAN.xcodeproj

clean:
	rm -rf .build YAN.xcodeproj DerivedData
