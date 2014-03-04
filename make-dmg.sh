#!/bin/sh -ex

VOLUME="Test Volume"
TMP_DMG="TEMP.dmg"
DMG="Test Volume.dmg"


# Create fresh empty dmg
rm -f "$TMP_DMG"
hdiutil create -size 50m -fs HFS+ -volname "$VOLUME" "$TMP_DMG"


# Mount it, and parse the output for the mount path
mount_point=`hdiutil attach -plist "$TMP_DMG" \
  | tr -d "\n\r" \
  | sed 's|.*<key>mount-point</key>\s*<string>\([^<]*\)</string>.*|\1|'`

echo "Mount point: $mount_point"

# Setup icon
cp meta/VolumeIcon.icns "$mount_point/.VolumeIcon.icns"
SetFile -a C "$mount_point"

# Setup background
mkdir -p "$mount_point/.background"
cp meta/background.jpg "$mount_point/.background/background.jpg"

# Copy files
cp content/README.dummy "$mount_point"


# Set window position, view style, icon positions etc.
osascript << EOF
tell application "Finder"
	tell disk "$VOLUME"
		open

		tell container window
			set bounds to {200, 100, 800, 580}
			set toolbar visible to false
			set statusbar visible to false
			set current view to icon view
		end tell

		-- Adjust Icon & Text Sizes
		set icon size of the icon view options of container window to 72
		set text size of the icon view options of container window to 12

		-- Set Background Image
		set background picture of the icon view options of container window to file ".background:background.jpg"

		-- Update Icon Positions
		set arrangement of the icon view options of container window to not arranged
		set position of item "README.dummy" of container window to {120, 364}
		--set position of item "SinglySDK.framework" of container window to {323, 364}
		--set position of item "SinglySDK.bundle" of container window to {478, 364}

		update without registering applications
		--delay 3
		--close
		eject
	end tell
end tell
EOF

# Finally, unmount it again
#hdiutil detach "$mount_point"

# Convert it into a compressed diskimage
rm -f "$DMG"
hdiutil convert "$TMP_DMG" -quiet -format UDZO -imagekey zlib-level=9 -o "$DMG"
