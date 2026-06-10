.PHONY: project open bump

project:
	xcodegen

open: project
	open Flame.xcodeproj

bump:
	@[ -z "$$(git status --porcelain)" ] || { echo "Git is not clean"; exit 1; }
	git push
	@OLD=$$(grep 'MARKETING_VERSION:' project.yml | awk '{print $$2}'); \
	NEW=$$(echo "$$OLD" | awk -F. '{printf "%s.%s.0", $$1, $$2+1}'); \
	DISPLAY=$$(echo "$$NEW" | sed 's/\.0$$//'); \
	sed -i '' "s/MARKETING_VERSION: $$OLD/MARKETING_VERSION: $$NEW/" project.yml; \
	xcodegen; \
	git add project.yml Flame.xcodeproj; \
	git commit -m "bumped to v$$DISPLAY post release"
