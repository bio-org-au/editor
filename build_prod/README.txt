The build_prod directory is here to hold two ed scripts that are 
called by the rake task build_prod.

You can see where these are called in the Jenkins tasks that build the Ruby Editor

Here's a snippet:

RAILS_ENV=production rake build_prod
cd ..
tar cfz ruby-editor.tgz ruby-editor


Note in case you test the scripts locally: 

The rake build_prod task rips git out of the directory because we don't want to commit
this back to github - it discards files not needed for production. ie. don't run it in the 
git repo without thinking 


