for file in ~/Desktop/*.png; do echo "$file"; convert "$file" -gravity center -crop 2560x1600+0+0 +repage "$file"; done
