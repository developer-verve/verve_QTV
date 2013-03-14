#!/bin/bash
echo "setting up Quick TV development environment"

HOME=`pwd`
BUILD_ENV=$1
BRANCH=$2

echo "setting up '$BUILD_ENV' environment for branch '$BRANCH' in $PWD for $USER"

INSTALL_LOCATION=/usr/local

PLAY_LOCATION=$INSTALL_LOCATION/play-current
PLAY_VERSION=1.2.4
PLAY_ID=development
PLAY_DOWNLOAD_PATH=http://download.playframework.org/releases/play-1.2.4.zip

FLEX_LOCATION=$INSTALL_LOCATION/flex-current
FLEX_VERSION=4.6.0.23201B
FLEX_DOWNLOAD_PATH=https://s3-eu-west-1.amazonaws.com/qtv.dependencies/flex_sdk_4.6.0.23201B.zip

if [ ! -d $INSTALL_LOCATION ]; then
	echo "$INSTALL_LOCATION doesn't exist, creating it"
else
	echo "$INSTALL_LOCATION exists"
fi

if [ ! -d "$INSTALL_LOCATION/play-$PLAY_VERSION" ]; then
	echo "play-$PLAY_VERSION doesn't exist"
	if [ ! -e $INSTALL_LOCATION/play-$PLAY_VERSION.zip ]; then
		echo "$INSTALL_LOCATION/play-$PLAY_VERSION.zip doesn't exist, downloading it"
		cd $INSTALL_LOCATION && sudo curl -O $PLAY_DOWNLOAD_PATH
	fi
	echo "unzipping $INSTALL_LOCATION/play-$PLAY_VERSION.zip"
	cd $INSTALL_LOCATION && sudo unzip $INSTALL_LOCATION/play-$PLAY_VERSION.zip
else
	echo "$INSTALL_LOCATION/play-$PLAY_VERSION exists"
fi

if [ -e $INSTALL_LOCATION/play-$PLAY_VERSION.zip ]; then
	sudo rm $INSTALL_LOCATION/play-$PLAY_VERSION.zip
fi
echo HERE
sudo chown -R $USER $INSTALL_LOCATION/play-$PLAY_VERSION

if [ -h $PLAY_LOCATION ]; then
	echo "$PLAY_LOCATION exists, removing it"
	sudo rm $PLAY_LOCATION
fi

echo "creating $PLAY_LOCATION"
ln -s $INSTALL_LOCATION/play-$PLAY_VERSION $PLAY_LOCATION

echo "checking for $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION"

if [ ! -d $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION ]; then
	echo "$INSTALL_LOCATION/flex_sdk_$FLEX_VERSION doesn't exist, creating it"
	sudo mkdir $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION
else
	echo "$INSTALL_LOCATION/flex_sdk_$FLEX_VERSION exists"
fi

if [ ! -e $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION/readme.htm ];then
	if [ ! -e $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION/flex_sdk_$FLEX_VERSION.zip ]; then
		echo "$INSTALL_LOCATION/flex_sdk_$FLEX_VERSION/flex_sdk_$FLEX_VERSION.zip doesn't exist, downloading it"
		cd $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION && sudo wget --no-check-certificate $FLEX_DOWNLOAD_PATH
	fi
	echo "unzipping $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION/flex_sdk_$FLEX_VERSION.zip"
	cd $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION && sudo unzip $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION/flex_sdk_$FLEX_VERSION.zip
else
	echo "looks like Flex SDK is unzipped"
fi

sudo chown -R $USER $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION

if [ -h $FLEX_LOCATION ]; then
	echo "$FLEX_LOCATION exists, removing it"
	sudo rm $FLEX_LOCATION
fi

echo "creating $FLEX_LOCATION"
ln -s $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION $FLEX_LOCATION

echo "making sure we're in $HOME before continuing"

cd $HOME

if [ ! -d $HOME/qtv-flex-core ]; then
	echo "cloning qtv-flex-core"
	git clone -b $BRANCH git@github.com:quicktv/qtv-flex-core.git
	sudo chown -R $USER $HOME/qtv-flex-core
else
	echo "updating qtv-flex-core"
	cd $HOME/qtv-flex-core && git pull origin $BRANCH && cd $HOME
fi

if [ ! -d "$HOME/qtv-webapp-client" ]; then
	echo "cloning qtv-webapp-client"
	git clone -b $BRANCH git@github.com:quicktv/qtv-webapp-client.git
	sudo chown -R $USER $HOME/qtv-webapp-client
else
	echo "updating qtv-webapp-client"
	cd $HOME/qtv-webapp-client && git pull origin $BRANCH && cd $HOME
fi

if [ ! -d "$HOME/qtv-interactive-video-player" ]; then
	echo "cloning qtv-interactive-video-player"
	git clone -b $BRANCH git@github.com:quicktv/qtv-interactive-video-player.git
	sudo chown -R $USER $HOME/qtv-interactive-video-player
else
	echo "updating qtv-interactive-video-player"
	cd $HOME/qtv-interactive-video-player && git pull origin $BRANCH && cd $HOME
fi

if [ ! -d "$HOME/qtv-play-webapp" ]; then 
	echo "cloning qtv-play-webapp"
	git clone -b $BRANCH git@github.com:quicktv/qtv-play-webapp.git
	sudo chown -R $USER $HOME/qtv-play-webapp
else
	echo "updating qtv-play-webapp"
	cd $HOME/qtv-play-webapp && git pull origin $BRANCH && cd $HOME
fi

if [ ! -d "$HOME/xuloo-haxe-ui" ]; then 
	echo "cloning xuloo-haxe-ui"
	git clone -b master git@github.com:quicktv/xuloo-haxe-ui.git
	sudo chown -R $USER $HOME/xuloo-haxe-ui
else
	echo "updating xuloo-haxe-ui"
	cd $HOME/xuloo-haxe-ui && git pull origin master && cd $HOME
fi

if [ ! -d "$HOME/qtv-haxe-ui" ]; then 
	echo "cloning qtv-haxe-ui"
	git clone -b master git@github.com:quicktv/qtv-haxe-ui.git
	sudo chown -R $USER $HOME/qtv-haxe-ui
else
	echo "updating qtv-haxe-ui"
	cd $HOME/qtv-haxe-ui && git pull origin master && cd $HOME
fi

if [ ! -d "$HOME/NME" ]; then 
	echo "cloning NME"
	git clone -b master git@github.com:quicktv/NME.git
	sudo chown -R $USER $HOME/NME
else
	echo "updating NME"
	cd $HOME/NME && git pull origin master && cd $HOME
fi

if [ ! -d "$HOME/sdl-static" ]; then 
	echo "checking out sdl-static"
	svn co http://sdl-static.googlecode.com/svn/trunk/ sdl-static
	sudo chown -R $USER $HOME/sdl-static
else
	echo "updating sdl-static"
	cd $HOME/sdl-static && svn up && cd $HOME
fi

echo "setting NME dev path in haxelib to '$HOME/NME'"

haxelib dev nme $HOME/NME 

haxelib install swf
haxelib install xfl
haxelib run nme rebuild tools

if [ ! -e $HOME/qtv-play-webapp/tmp/flex.framework/flex_sdk_$FLEX_VERSION.zip ]; then
	echo "copying the flex framework zip from /usr/local/flex-current into the webapp/tmp directory..."
	sudo mkdir -p $HOME/qtv-play-webapp/tmp/flex.framework/
	sudo cp $INSTALL_LOCATION/flex_sdk_$FLEX_VERSION/flex_sdk_$FLEX_VERSION.zip $HOME/qtv-play-webapp/tmp/flex.framework
	cd $HOME/qtv-play-webapp/tmp/flex.framework/
	echo "... and unzipping it"
	sudo unzip $HOME/qtv-play-webapp/tmp/flex.framework/flex_sdk_$FLEX_VERSION.zip
	sudo chown -R $USER $HOME/qtv-play-webapp/tmp/flex.framework
	cd $HOME
fi

#if [ ! -d "$HOME/qtv-java-support" ]; then 
#	echo "cloning qtv-java-support"
#	git clone git@github.com:quicktv/qtv-java-support.git
#	chown -R $USER $HOME/qtv-java-support
#else
#	echo "updating qtv-java-support"
#	cd $HOME/qtv-java-support && git pull && cd $HOME
#fi

#echo "building the qtv-java-support projects"
#cd $HOME/qtv-java-support && mvn clean install && cd $HOME

echo "setting Play! Framework id to 'development'"
echo "$PLAY_ID" | $PLAY_LOCATION/play id

echo "resolving webapp dependencies and creating eclipse project files"
cd $HOME/qtv-play-webapp && $PLAY_LOCATION/play deps --sync && $PLAY_LOCATION/play eclipsify

echo "making $USER owner of $HOME/qtv-play-webapp/eclipse"
sudo chown -R $USER $HOME/qtv-play-webapp/eclipse

echo "making $USER owner of $HOME/qtv-play-webapp/modules"
sudo chown -R $USER $HOME/qtv-play-webapp/modules

echo "creating the local qtv.release.* directories"
mkdir -p $HOME/qtv-play-webapp/tmp/qtv.release.development && sudo chown -R $USER $HOME/qtv-play-webapp/tmp/qtv.release.development
mkdir -p $HOME/qtv-play-webapp/public/scratch/qtv.release.development && sudo chown -R $USER $HOME/qtv-play-webapp/public/scratch/qtv.release.development

echo "cleaning and staging flash client files"
cd $HOME && ant stage -Dbuild.env=$BUILD_ENV

