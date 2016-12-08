#!/bin/bash

#umask 002
export HOME=/opt/minecraft/data
cd /opt/minecraft/data

function installForge {
  TYPE=FORGE
  norm=$VANILLA_VERSION

  echo "Checking Forge version information."
  case $FORGEVERSION in
    RECOMMENDED)
      curl -o /tmp/forge.json -sSL http://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions_slim.json
      FORGE_VERSION=$(cat /tmp/forge.json | jq -r ".promos[\"$norm-recommended\"]")
      if [ $FORGE_VERSION = null ]; then
        FORGE_VERSION=$(cat /tmp/forge.json | jq -r ".promos[\"$norm-latest\"]")
        if [ $FORGE_VERSION = null ]; then
          echo "ERROR: Version $FORGE_VERSION is not supported by Forge"
          echo "       Refer to http://files.minecraftforge.net/ for supported versions"
          exit 2
        fi
      fi
      ;;

    *)
      FORGE_VERSION=$FORGEVERSION
      ;;
  esac

  # URL format changed for 1.7.10 from 10.13.2.1300
  sorted=$((echo $FORGE_VERSION; echo 10.13.2.1300) | sort -V | head -1)
  if [[ $norm == '1.7.10' && $sorted == '10.13.2.1300' ]]; then
      # if $FORGEVERSION >= 10.13.2.1300
      normForgeVersion="$norm-$FORGE_VERSION-$norm"
  else
      normForgeVersion="$norm-$FORGE_VERSION"
  fi

  FORGE_INSTALLER="forge-$normForgeVersion-installer.jar"
  SERVER="forge-$normForgeVersion-universal.jar"

  if [ ! -e "$SERVER" ]; then
    echo "Downloading $FORGE_INSTALLER ..."
    wget -q http://files.minecraftforge.net/maven/net/minecraftforge/forge/$normForgeVersion/$FORGE_INSTALLER
    echo "Installing $SERVER"
    java -jar $FORGE_INSTALLER --installServer
  fi
}

function setServerProp {
  local prop=$1
  local var=$2
  if [ -n "$var" ]; then
    echo "Setting $prop to $var"
    sed -i "/$prop\s*=/ c $prop=$var" /opt/minecraft/data/server.properties
  fi

}

if [ ! -e /opt/minecraft/data/eula.txt ]; then
  if [ "$EULA" != "" ]; then
    echo "# Generated via Docker on $(date)" > eula.txt
    echo "eula=$EULA" >> eula.txt
  else
    echo ""
    echo "Please accept the Minecraft EULA at"
    echo "  https://account.mojang.com/documents/minecraft_eula"
    echo "by adding the following immediately after 'docker run':"
    echo "  -e EULA=TRUE"
    echo ""
    exit 1
  fi
fi

VERSIONS_JSON=https://launchermeta.mojang.com/mc/game/version_manifest.json

echo "Checking version information."
case "X$VERSION" in
  X|XLATEST|Xlatest)
    VANILLA_VERSION=`curl -sSL $VERSIONS_JSON | jq -r '.latest.release'`
  ;;
  XSNAPSHOT|Xsnapshot)
    VANILLA_VERSION=`curl -sSL $VERSIONS_JSON | jq -r '.latest.snapshot'`
  ;;
  X[1-9]*)
    VANILLA_VERSION=$VERSION
  ;;
  *)
    VANILLA_VERSION=`curl -sSL $VERSIONS_JSON | jq -r '.latest.release'`
  ;;
esac

echo "Installing Forge."
installForge

# If supplied with a URL for a world, download it and unpack
if [[ "$WORLD" ]]; then
case "X$WORLD" in
  X[Hh][Tt][Tt][Pp]*)
    echo "Downloading world via HTTP"
    echo "$WORLD"
    wget -q -O - "$WORLD" > /opt/minecraft/data/world.zip
    echo "Unzipping word"
    unzip -q /opt/minecraft/data/world.zip
    rm -f /opt/minecraft/data/world.zip
    if [ ! -d /opt/minecraft/data/world ]; then
      echo World directory not found
      for i in /opt/minecraft/data/*/level.dat; do
        if [ -f "$i" ]; then
          d=`dirname "$i"`
          echo Renaming world directory from $d
          mv -f "$d" /opt/minecraft/data/world
        fi
      done
    fi
    ;;
  *)
    echo "Invalid URL given for world: Must be HTTP or HTTPS and a ZIP file"
    ;;
esac
fi

# If supplied with a URL for a config (simple zip of configs), download it and unpack
if [[ "$CONFIGS" ]]; then
case "X$CONFIGS" in
  X[Hh][Tt][Tt][Pp]*[Zz][iI][pP])
    echo "Downloading configs via HTTP"
    echo "$CONFIGS"
    wget -q -O /tmp/configs.zip "$CONFIGS"
    mkdir -p /opt/minecraft/data/config
    unzip -o -d /opt/minecraft/data/config /tmp/configs.zip
    rm -f /tmp/configs.zip
    ;;
  *)
    echo "Invalid URL given for configs: Must be HTTP or HTTPS and a ZIP file"
    ;;
esac
fi

# If supplied with a URL for a modpack (simple zip of jars), download it and unpack
if [[ "$MODPACK" ]]; then
case "X$MODPACK" in
  X[Hh][Tt][Tt][Pp]*[Zz][iI][pP])
    echo "Downloading mod/plugin pack via HTTP"
    echo "$MODPACK"
    wget -q -O /tmp/modpack.zip "$MODPACK"
    mkdir -p /opt/minecraft/data/mods
    unzip -o -d /opt/minecraft/data/mods /tmp/modpack.zip
    rm -f /tmp/modpack.zip
    ;;
  *)
    echo "Invalid URL given for modpack: Must be HTTP or HTTPS and a ZIP file"
    ;;
esac
fi

if [ ! -e server.properties ]; then
  echo "Creating server.properties"
  cp /tmp/server.properties .

  if [ -n "$WHITELIST" ]; then
    echo "Creating whitelist"
    sed -i "/whitelist\s*=/ c whitelist=true" /opt/minecraft/data/server.properties
    sed -i "/white-list\s*=/ c white-list=true" /opt/minecraft/data/server.properties
  fi

  setServerProp "motd" "$MOTD"
  setServerProp "allow-nether" "$ALLOW_NETHER"
  setServerProp "announce-player-achievements" "$ANNOUNCE_PLAYER_ACHIEVEMENTS"
  setServerProp "enable-command-block" "$ENABLE_COMMAND_BLOCK"
  setServerProp "spawn-animals" "$SPAWN_ANIMAILS"
  setServerProp "spawn-monsters" "$SPAWN_MONSTERS"
  setServerProp "spawn-npcs" "$SPAWN_NPCS"
  setServerProp "generate-structures" "$GENERATE_STRUCTURES"
  setServerProp "spawn-npcs" "$SPAWN_NPCS"
  setServerProp "view-distance" "$VIEW_DISTANCE"
  setServerProp "hardcore" "$HARDCORE"
  setServerProp "max-build-height" "$MAX_BUILD_HEIGHT"
  setServerProp "force-gamemode" "$FORCE_GAMEMODE"
  setServerProp "hardmax-tick-timecore" "$MAX_TICK_TIME"
  setServerProp "enable-query" "$ENABLE_QUERY"
  setServerProp "query.port" "$QUERY_PORT"
  setServerProp "enable-rcon" "$ENABLE_RCON"
  setServerProp "rcon.password" "$RCON_PASSWORD"
  setServerProp "rcon.port" "$RCON_PORT"
  setServerProp "max-players" "$MAX_PLAYERS"
  setServerProp "max-world-size" "$MAX_WORLD_SIZE"
  setServerProp "level-name" "$LEVEL"
  setServerProp "level-seed" "$SEED"
  setServerProp "pvp" "$PVP"
  setServerProp "generator-settings" "$GENERATOR_SETTINGS"

  if [ -n "$LEVEL_TYPE" ]; then
    # normalize to uppercase
    LEVEL_TYPE=${LEVEL_TYPE^^}
    echo "Setting level type to $LEVEL_TYPE"
    # set the level type
    sed -i "/level-type\s*=/ c level-type=$LEVEL_TYPE" /opt/minecraft/data/server.properties 
  fi

  if [ -n "$DIFFICULTY" ]; then
    case $DIFFICULTY in
      peaceful|0)
        DIFFICULTY=0
        ;;
      easy|1)
        DIFFICULTY=1
        ;;
      normal|2)
        DIFFICULTY=2
        ;;
      hard|3)
        DIFFICULTY=3
        ;;
      *)
        echo "DIFFICULTY must be peaceful, easy, normal, or hard."
        exit 1
        ;;
    esac
    echo "Setting difficulty to $DIFFICULTY"
    sed -i "/difficulty\s*=/ c difficulty=$DIFFICULTY" /opt/minecraft/data/server.properties
  fi

  if [ -n "$MODE" ]; then
    echo "Setting mode"
    case ${MODE,,?} in
      0|1|2|3)
        ;;
      s*)
        MODE=0
        ;;
      c*)
        MODE=1
        ;;
      a*)
        MODE=2
        ;;
      s*)
        MODE=3
        ;;
      *)
        echo "ERROR: Invalid game mode: $MODE"
        exit 1
        ;;
    esac

    sed -i "/gamemode\s*=/ c gamemode=$MODE" /opt/minecraft/data/server.properties
  fi
fi


if [ -n "$OPS" -a ! -e ops.txt.converted ]; then
  echo "Setting ops"
  echo $OPS | awk -v RS=, '{print}' >> ops.txt
fi

if [ -n "$WHITELIST" -a ! -e white-list.txt.converted ]; then
  echo "Setting whitelist"
  echo $WHITELIST | awk -v RS=, '{print}' >> white-list.txt
fi

# Make sure files exist to avoid errors
if [ ! -e banned-players.json ]; then
	echo '' > banned-players.json
fi
if [ ! -e banned-ips.json ]; then
	echo '' > banned-ips.json
fi

# If any modules have been provided, copy them over
[ -d /opt/minecraft/data/mods ] || mkdir /opt/minecraft/data/mods
for m in /opt/minecraft/mods/*.jar
do
  if [ -f "$m" ]; then
    echo Copying mod `basename "$m"`
    cp -f "$m" /opt/minecraft/data/mods
  fi
done
[ -d /opt/minecraft/data/config ] || mkdir /opt/minecraft/data/config
for c in /opt/minecraft/config/*
do
  if [ -f "$c" ]; then
    echo Copying configuration `basename "$c"`
    cp -rf "$c" /opt/minecraft/data/config
  fi
done

# If we have a bootstrap.txt file... feed that in to the server stdin
if [ -f /opt/minecraft/data/bootstrap.txt ];
then
    exec java $JVM_OPTS -jar $SERVER "$@" < /opt/minecraft/data/bootstrap.txt
else
    echo Starting forge server
    exec java $JVM_OPTS -jar $SERVER "$@"
fi

