#!/bin/bash

if [ -z "$1" ]
then
   echo "No build mode input"
   echo "Usage : ./buildChromium.sh Debug or Release"
   exit 1
fi

export CCACHE_PREFIX=icecc
export CHROME_DEVEL_SANDBOX=/usr/local/sbin/chrome-devel-sandbox
export CCACHE_BASEDIR=$HOME/chromium
export ICECC_CLANG_REMOTE_CPP=1
export ICECC_VERSION=$HOME/chromium/clang.tar.gz
export CHROMIUM_SRC=$HOME/chromium/src # Please set the chromium src path in your local.
export PATH=/usr/lib/ccache:/usr/lib/icecc/bin:$PATH
export PATH=$CHROMIUM_SRC/third_party/llvm-build/Release+Asserts/bin:$PATH

export GN_DEFINES='is_component_build=true symbol_level=1 dcheck_always_on=true'
export GN_DEFINES=$GN_DEFINES' enable_nacl=false treat_warnings_as_errors=false'
export GN_DEFINES=$GN_DEFINES' proprietary_codecs=true ffmpeg_branding="Chrome"'
export GN_DEFINES=$GN_DEFINES' use_debug_fission=false linux_use_bundled_binutils=false clang_use_chrome_plugins=false cc_wrapper="icecc" ffmpeg_use_atomics_fallback=true enable_swiftshader=false use_jumbo_build = true '
export GN_DEFINES=$GN_DEFINES' google_api_key="???" google_default_client_id="??.com" google_default_client_secret="??"'
echo "GN_DEFINES: "$GN_DEFINES

if [ "$1" == Debug ];
then
  gn gen out/Debug "--args=is_debug=true $GN_DEFINES"
else
  gn gen out/Release "--args=is_debug=false $GN_DEFINES"
fi

echo "============================================="
timestamp=$(date +"%T")
echo "[$timestamp] Start compiling Chromium on $1 mode"
ninja -j 100 -C out/"$1" chrome
timestamp=$(date +"%T")
echo "[$timestamp] Finish to compile Chromium!"
echo "============================================="
