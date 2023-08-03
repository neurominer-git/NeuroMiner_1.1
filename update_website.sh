echo "updating NeuroMiner website (jupyter book and github pages)"

jupyter-book clean ./docs/ --all
jupyter-book build ./docs   
git add ./docs/
git commit -m 'updating website'
git push 
cd docs
ghp-import -n -p -f _build/html


echo "Done, changes to website should be visible in about 2min"
