.PHONY: all clean carthage carthage-clean cocoapods cocoapods-clean

all: carthage cocoapods

clean: carthage-clean cocoapods-clean

carthage:
	carthage bootstrap --platform iOS --no-use-binaries --cache-builds
	xcodebuild -project ApolloDeveloperKitInstallTests.xcodeproj -scheme ApolloDeveloperKitInstallTests-Carthage -sdk iphonesimulator build

carthage-clean:
	$(RM) -R Carthage Cartfile.resolved

cocoapods:
	pod install
	xcodebuild -workspace ApolloDeveloperKitInstallTests.xcworkspace -scheme ApolloDeveloperKitInstallTests-CocoaPods -sdk iphonesimulator build

cocoapods-clean:
	pod deintegrate
