.PHONY: project open

project:
	xcodegen

open: project
	open Flame.xcodeproj
