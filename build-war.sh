#!/bin/bash

if [ $1 = "setup" ]; then
  . ./setup-dev-linux.sh
fi

export JAVA_OPTS='-server -d64'

rm *.war || echo "no war files"

echo "which jruby"
which jruby

echo PATH:- $PATH

echo "java -version"
java -version

echo "jruby -v"
jruby -v

echo "remove pry from Gemfile"
sed -i 's/gem.*pry/\# &/' Gemfile

echo "bundle exec rake assets:clobber"
bundle exec rake assets:clobber

echo "bundle exec rake assets:precompile  RAILS_ENV=production RAILS_RELATIVE_URL_ROOT=/nsl/editor"
bundle exec rake assets:precompile  RAILS_ENV=production  RAILS_RELATIVE_URL_ROOT=/nsl/editor 

echo "bundle exec warble"
bundle exec warble
