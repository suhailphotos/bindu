# work from anywhere; repo lives at ~/.config
git -C ~/.config switch vimira
git -C ~/.config fetch origin

# 1) define a repo-local merge driver that always keeps "ours"
git -C ~/.config config merge.ours.driver true
git -C ~/.config config merge.ours.name "Keep ours during merges (for nvim/)"

# 2) tell Git to use that driver for everything under nvim/ (ON THIS BRANCH)
printf "nvim/** merge=ours\n" >> ~/.config/.gitattributes
git -C ~/.config add .gitattributes
git -C ~/.config commit -m "vimira: keep nvim/** untouched when merging main"
