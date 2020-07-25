#!/bin/sh

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

version="$REPLACE_WITH_VERSION$"

user="$(id -un 2>/dev/null || true)"

sh_c='sh -c'

if [ "$user" != 'root' ]; then
	if command_exists sudo; then
		sh_c='sudo -E sh -c'
	elif command_exists su; then
		sh_c='su -c'
	else
		cat >&2 <<-'EOF'
		Error: this installer needs the ability to run commands as root.
		We are unable to find either "sudo" or "su" available to make this happen.
		EOF
		exit 1
	fi
fi

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=linux;;
    Darwin*)    machine=macos;;
    CYGWIN*)    machine=win.exe;;
    MINGW*)     machine=win.exe;;
    *)          machine="UNKNOWN"
esac

# If unknown we need to abort the install
if [ "$machine" = 'UNKNOWN' ]; then
	cat >&2 <<-'EOF'
		Unknown distribution $unameOut
		Please download distribution from https://github.com/ralleyio/ralley-cli/releases/tag/$version
		EOF
		exit 1
fi

# Check for alpine linux
if [ "$machine" = 'linux' ]; then
	linuxId="$(cat /etc/os-release | grep ID=alpine)"
	if [ "$linuxId" = "ID=alpine" ]; then
		machine='alpine'
	fi
fi

# Linux requires wget, gunzip
if [ "$machine" = 'linux' ]; then
	$sh_c 'apt-get update -qq >/dev/null && apt-get install wget -y -qq'
	$sh_c "apt-get install -y -qq --no-install-recommends wget gunzip >/dev/null"
fi

# Alpine requires libstdc
if [ "$machine" = 'alpine' ]; then
	$sh_c 'apk add libstdc++'
fi

# Download URL for Github
downloadUrl="https://github.com/ralleyio/ralley-cli/releases/download/$version/ralley-$machine.gz"

echo
echo "  --------------------"
echo "  Installing Ralley CLI"
echo "  --------------------"
echo
echo "  Downloading Ralley CLI binary from $downloadUrl"
echo

if command_exists wget; then
	$sh_c "wget -qO- $downloadUrl | gunzip -f -c > /usr/local/bin/ralley"
	$sh_c "chmod +x /usr/local/bin/ralley"
elif command_exists curl; then
	$sh_c "curl -SLs $downloadUrl | gunzip -f -c > /usr/local/bin/ralley"
	$sh_c "chmod +x /usr/local/bin/ralley"
else
	echo ""
	echo "[ERR] Installer requires wget or curl"
	echo ""
	exit 1
fi

echo
echo "  Installation complete!"
echo
echo "  Try the following command to check it's working:"
echo
echo "    $ ralley -h"
echo
echo

