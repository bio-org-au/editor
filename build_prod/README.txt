

Note: this is for buildng the ruby version (not the jruby version) so 
make sure you've switched it to ruby - see the switch-to-ruby directory.

Also, build_prod stops this being a git repo because we don't want to commit
this back to git - it discards files not needed for production.




rake build_prod

cd ..
tar cvzf ruby-editor.tgz <this dir>

