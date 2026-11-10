.PHONY: all build run clean project open

all: build

project:
	xcodegen generate

build:
	xcodebuild -project YAN.xcodeproj -scheme YAN -configuration Debug build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""

run:
	@killall YAN 2>/dev/null || true
	open "$$(find ~/Library/Developer/Xcode/DerivedData/YAN-*/Build/Products/Debug/YAN.app -maxdepth 0 2>/dev/null | head -n 1)"

open:
	open YAN.xcodeproj

clean:
	rm -rf .build YAN.xcodeproj DerivedData
