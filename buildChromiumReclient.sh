#!/bin/bash

# This script is to build Chromium using Reclient.

if [ "$#" -lt 1 ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
   echo "Usage : buildChromiumReclient.sh [Build options] [Test modules] [Options]"
   echo ""
   echo "Build options:"
   echo "  Debug                  Debug build"
   echo "  Release                Release build"
   echo "  ChromeOS               ChromeOS build (Only debug build)"
   echo "  Android                Android build (Only debug build)"
   echo ""
   echo "Test modules:"
   echo "  all_tests              All Tests"
   echo "  blink_tests            Blink Test"
   echo "  content_browsertests   Content module browser test"
   echo "  content_unittests      Content module unit test"
   echo "  unit_tests             Chrome UI unit test"
   echo ""
   echo "Options:"
   echo " --sync                  Run glient sync"
   echo " --start-goma-service    Start Goma client service"
   exit 1
fi

export GOMA_LOCAL_OUTPUT_CACHE_DIR=/home/gyuyoung/.goma-cache
export GOMA_LOCAL_OUTPUT_CACHE_MAX_CACHE_AMOUNT_IN_MB=10000

# Start Goma client service.
if [ "$1" == --start-goma-service ] || [ "$1" == start-goma-service ];
then
  ~/goma/goma_ctl.py restart
  exit 0
fi

# Do gclient sync.
if [ "$1" == --sync ] || [ "$1" == sync ];
then
  timestamp=$(date +"%T")
  echo "[$timestamp] Start gclient sync."
  gclient sync -D
  timestamp=$(date +"%T")
  echo "[$timestamp] Finish gclient sync."
  exit 0
fi

# Set Chromium gn build arguments.
timestamp=$(date +"%T")
echo "[$timestamp] 1. Configuration"
export GN_DEFINES='is_component_build=true use_remoteexec = true reclient_cfg_dir = "../../buildtools/reclient_cfgs/linux"'

# Start building Chromium using the gn configuration.
if [ "$1" == Debug ];
then
  export GN_DEFINES=$GN_DEFINES' dcheck_always_on=true'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/Debug "--args=is_debug=true $GN_DEFINES"
elif [ "$1" == Release ];
then
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/Release "--args=is_debug=false $GN_DEFINES"
elif [ "$1" == ChromeOS ];
then
  export GN_DEFINES=$GN_DEFINES' target_os="chromeos"'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/ChromeOS "--args=is_debug=true $GN_DEFINES"
elif [ "$1" == Chromecast ];
then
  export GN_DEFINES=$GN_DEFINES' is_chromecast=true'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/Chromecast "--args=is_debug=true $GN_DEFINES"
elif [ "$1" == GCC ];
then
  export GN_DEFINES=$GN_DEFINES' is_clang=false'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/GCC "--args=is_debug=true $GN_DEFINES"
elif [ "$1" == Android ];
then
  export GN_DEFINES=$GN_DEFINES' target_os="android" target_cpu="x86"'
  echo "GN_DEFINES: "$GN_DEFINES
#  gclient runhooks
  gn gen out/Android "--args=is_debug=true $GN_DEFINES"
elif [ "$1" == Ozone ];
then
  export GN_DEFINES=$GN_DEFINES' use_ozone=true use_xkbcommon=true use_system_minigbm=true use_system_libdrm=true'
  echo "GN_DEFINES: "$GN_DEFINES
  gn gen out/Ozone "--args=is_debug=true $GN_DEFINES"
else
  echo "Undefined Debug or Release."
  exit 0
fi

ulimit -n 4096

JOBS=1000
ALL_TESTS='unit_tests components_unittests browser_tests cc_unittests blink_tests app_shell_unittests services_unittests content_browsertests content_unittests webkit_unit_tests viz_unittests media_unittests'

start_timestamp=$(date +"%T")
if [ "$1" == Android ];
then
  echo ""
  echo "[$start_timestamp] 2. Start compiling Chromium on $1 mode using Reclient"
  time autoninja -j $JOBS -C out/"$1" chrome_public_apk ${@:2}
elif [ "$1" == Chromecast ];
then
  echo ""
  echo "[$start_timestamp] 2. Start compiling Chromium on $1 mode using Reclient"
  time autoninja -j $JOBS -C out/"$1" cast_shell ${@:2}
else
  echo ""
  echo "[$start_timestamp] 2. Start compiling Chromium on $1 mode using Reclient"
  if [ "$2" == all_tests ]
  then
    time autoninja -j $JOBS -C out/"$1" chrome $ALL_TESTS
  else
    time autoninja -j $JOBS -C out/"$1" chrome ${@:2}
  fi
fi

end_timestamp=$(date +"%T")
echo ""
echo "[$end_timestamp] 3. Finish to compile Chromium!"

