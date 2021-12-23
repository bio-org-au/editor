#! /bin/bash

# JAVA
echo "** setting up Java"
if [ -z "$JAVA_HOME" ]; then
  if [ -z "$(type -p java)" ]; then
    if [ -z "$SDKMAN_VERSION" ]; then
      echo "Trying to install/use java via SDKMAN"
      sdk use java 8.0.252.hs-adpt
    else
      echo "!! You need java. Perhaps use sdkman https://sdkman.io"
      exit 1
    fi
  else
    JAVA_HOME="$(type -p java | sed 's/\/bin\/java$//g')"
    echo "JAVA_HOME not set but java is on the path. Setting JAVA_HOME=$JAVA_HOME"
  fi
elif [ ! -x "$JAVA_HOME/bin/java" ]; then
  echo "!! JAVA_HOME is set but no java executable. You need java. Perhaps use sdkman https://sdkman.io"
  exit 1
fi

if [ -z "${JAVA_HOME}" ]; then
  echo "!! Something went wrong and JAVA_HOME is not set. Probably SDKMAN failed?"
  exit 1
fi

_java="$JAVA_HOME/bin/java"
_jversion=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}' | grep "1.8")
if [[ -z "$_jversion" ]]; then
  echo "!! Wrong version of java in ${JAVA_HOME}, we need 1.8. Perhaps use sdkman https://sdkman.io"
  exit 1
fi

#check PATH contains this java version
if [ -z "$(echo $PATH | grep "$JAVA_HOME/bin}")" ]; then
  PATH=$JAVA_HOME/bin:$PATH
fi

echo "** JAVA VERSION"
java -version

JAVA_OPTS='-server -d64'

# JRUBY
echo "** setting up JRuby"
JRUBY_VERSION=9.3.1.0
TOOLS=build-tools
JRUBY_ZIP=${TOOLS}/jruby-dist-${JRUBY_VERSION}-bin.zip
JRUBY_HOME=$PWD/${TOOLS}/jruby-${JRUBY_VERSION}

if [ ! -d "$TOOLS" ]; then
  mkdir -p $TOOLS || (
    echo "Couldn't create tools directory."
    exit 1
  ) || exit 1
fi

if [ ! -d "$JRUBY_HOME" ]; then
  if [ ! -f "$JRUBY_ZIP" ]; then
    echo "Downloading JRuby $JRUBY_VERSION"
    curl https://repo1.maven.org/maven2/org/jruby/jruby-dist/${JRUBY_VERSION}/jruby-dist-${JRUBY_VERSION}-bin.zip --output $JRUBY_ZIP
    test $?=0 || (
      echo "downloading jruby failed"
      exit 1
    ) || exit 1
    echo "==> Downloaded JRuby"
  fi
  echo "Unzipping JRuby"
  unzip -q -d $TOOLS $JRUBY_ZIP
fi

#check PATH contains this java version
if [ -z "$(echo $PATH | grep "$JRUBY_HOME/bin}")" ]; then
  PATH=$JRUBY_HOME/bin:$PATH
fi

echo "** JRUBY VERSION"
jruby -v
echo "JRUBY_HOME $JRUBY_HOME"

if [ -z "$(type -p yarn)" ]; then
  echo "!! You need to install yarn see https://classic.yarnpkg.com/en/docs/install#centos-stable"
  exit 1
fi

if [ -z "$(type -p node)" ]; then
  echo "!! You need to install node see https://nodejs.org/en/download/package-manager/#enterprise-linux-and-fedora"
  exit 1
fi

echo "*** setting config file location environment variables to ~/.nsl/..."
EDITOR_CONFIG_FILE=$HOME/.nsl/editor-r6-config.rb
EDITOR_CONFIGDB_FILE=$HOME/.nsl/editor-database.yml
export EDITOR_CONFIG_FILE EDITOR_CONFIGDB_FILE

export JAVA_OPTS JRUBY_HOME PATH

echo "** info"
echo "PATH: $PATH"
echo " "
echo ">>> bootstrapping"
yarn
#if [ -z "$(type -p bundler)" ]; then
  #echo "Installing bundler..."
  #gem install bundler -N || exit 1
#fi
gem install bundler -v 2.2.29 -N 
gem install bundler -N 
bundle install
echo "<<< bootstrapped"
echo " "
echo "* You're all set *"
