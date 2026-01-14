#!/bin/sh
# Copyright (c) Tailscale Inc & AUTHORS
# SPDX-License-Identifier: BSD-3-Clause
#
# MODIFIED BY: Gemini (At User Request)
# Added automatic 'tailscale up --qr' execution at the end.
#
# Environment variables:
#   TRACK: Set to "stable" or "unstable" (default: stable)
#   TAILSCALE_VERSION: Pin to a specific version (e.g., "1.88.4")

set -eu

main() {
	# Step 1: detect the current linux distro, version, and packaging system.
	OS=""
	VERSION=""
	PACKAGETYPE=""
	APT_KEY_TYPE="" # Only for apt-based distros
	APT_SYSTEMCTL_START=false # Only needs to be true for Kali
	TRACK="${TRACK:-stable}"
	TAILSCALE_VERSION="${TAILSCALE_VERSION:-}"

	case "$TRACK" in
		stable|unstable)
			;;
		*)
			echo "unsupported track $TRACK"
			exit 1
			;;
	esac

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		VERSION_MAJOR="${VERSION_ID:-}"
		VERSION_MAJOR="${VERSION_MAJOR%%.*}"
		case "$ID" in
			ubuntu|pop|neon|zorin|tuxedo)
				OS="ubuntu"
				if [ "${UBUNTU_CODENAME:-}" != "" ]; then
				    VERSION="$UBUNTU_CODENAME"
				else
				    VERSION="$VERSION_CODENAME"
				fi
				PACKAGETYPE="apt"
				if [ "$VERSION_MAJOR" -lt 20 ]; then
					APT_KEY_TYPE="legacy"
				else
					APT_KEY_TYPE="keyring"
				fi
				;;
			debian)
				OS="$ID"
				VERSION="$VERSION_CODENAME"
				PACKAGETYPE="apt"
				if [ -z "${VERSION_ID:-}" ]; then
					APT_KEY_TYPE="keyring"
				elif [ "$NAME" = "Parrot Security" ]; then
					APT_KEY_TYPE="keyring"
					VERSION=bookworm
				elif [ "$VERSION_MAJOR" -lt 11 ]; then
					APT_KEY_TYPE="legacy"
				else
					APT_KEY_TYPE="keyring"
				fi
				;;
			linuxmint)
				if [ "${UBUNTU_CODENAME:-}" != "" ]; then
				    OS="ubuntu"
				    VERSION="$UBUNTU_CODENAME"
				elif [ "${DEBIAN_CODENAME:-}" != "" ]; then
				    OS="debian"
				    VERSION="$DEBIAN_CODENAME"
				else
				    OS="ubuntu"
				    VERSION="$VERSION_CODENAME"
				fi
				PACKAGETYPE="apt"
				if [ "$VERSION_MAJOR" -lt 5 ]; then
					APT_KEY_TYPE="legacy"
				else
					APT_KEY_TYPE="keyring"
				fi
				;;
			elementary)
				OS="ubuntu"
				VERSION="$UBUNTU_CODENAME"
				PACKAGETYPE="apt"
				if [ "$VERSION_MAJOR" -lt 6 ]; then
					APT_KEY_TYPE="legacy"
				else
					APT_KEY_TYPE="keyring"
				fi
				;;
			industrial-os)
				OS="debian"
				PACKAGETYPE="apt"
				if [ "$VERSION_MAJOR" -lt 5 ]; then
					VERSION="buster"
					APT_KEY_TYPE="legacy"
				else
					VERSION="bullseye"
					APT_KEY_TYPE="keyring"
				fi
				;;
			parrot|mendel)
				OS="debian"
				PACKAGETYPE="apt"
				if [ "$VERSION_MAJOR" -lt 5 ]; then
					VERSION="buster"
					APT_KEY_TYPE="legacy"
				else
					VERSION="bullseye"
					APT_KEY_TYPE="keyring"
				fi
				;;
			galliumos)
				OS="ubuntu"
				PACKAGETYPE="apt"
				VERSION="bionic"
				APT_KEY_TYPE="legacy"
				;;
			pureos|kaisen)
				OS="debian"
				PACKAGETYPE="apt"
				VERSION="bullseye"
				APT_KEY_TYPE="keyring"
				;;
			raspbian)
				OS="$ID"
				VERSION="$VERSION_CODENAME"
				PACKAGETYPE="apt"
				if [ "$VERSION_MAJOR" -lt 11 ]; then
					APT_KEY_TYPE="legacy"
				else
					APT_KEY_TYPE="keyring"
				fi
				;;
			kali)
				OS="debian"
				PACKAGETYPE="apt"
				APT_SYSTEMCTL_START=true
				if [ "$VERSION_MAJOR" -lt 2021 ]; then
					VERSION="buster"
					APT_KEY_TYPE="legacy"
				else
					VERSION="bullseye"
					APT_KEY_TYPE="keyring"
				fi
				;;
			Deepin|deepin)
				OS="debian"
				PACKAGETYPE="apt"
				if [ "$VERSION_MAJOR" -lt 20 ]; then
					APT_KEY_TYPE="legacy"
					VERSION="buster"
				else
					APT_KEY_TYPE="keyring"
					VERSION="bullseye"
				fi
				;;
			pika)
				PACKAGETYPE="apt"
				APT_KEY_TYPE="keyring"
				if [ "$VERSION_MAJOR" -lt 4 ]; then
					OS="ubuntu"
					VERSION="$UBUNTU_CODENAME"
				else
					OS="debian"
					VERSION="$DEBIAN_CODENAME"
				fi
				;;
			sparky)
				OS="debian"
				PACKAGETYPE="apt"
				VERSION="$DEBIAN_CODENAME"
				APT_KEY_TYPE="keyring"
				;;
			centos)
				OS="$ID"
				VERSION="$VERSION_MAJOR"
				PACKAGETYPE="dnf"
				if [ "$VERSION" = "7" ]; then
					PACKAGETYPE="yum"
				fi
				;;
			ol)
				OS="oracle"
				VERSION="$VERSION_MAJOR"
				PACKAGETYPE="dnf"
				if [ "$VERSION" = "7" ]; then
					PACKAGETYPE="yum"
				fi
				;;
			rhel|miraclelinux)
				OS="$ID"
				if [ "$ID" = "miraclelinux" ]; then
					OS="rhel"
				fi
				VERSION="$VERSION_MAJOR"
				PACKAGETYPE="dnf"
				if [ "$VERSION" = "7" ]; then
					PACKAGETYPE="yum"
				fi
				;;
			fedora)
				OS="$ID"
				VERSION=""
				PACKAGETYPE="dnf"
				;;
			rocky|almalinux|nobara|openmandriva|sangoma|risios|cloudlinux|alinux|fedora-asahi-remix|ultramarine)
				OS="fedora"
				VERSION=""
				PACKAGETYPE="dnf"
				;;
			amzn)
				OS="amazon-linux"
				VERSION="$VERSION_ID"
				PACKAGETYPE="yum"
				;;
			xenenterprise)
				OS="centos"
				VERSION="$VERSION_MAJOR"
				PACKAGETYPE="yum"
				;;
			opensuse-leap|sles)
				OS="opensuse"
				VERSION="leap/$VERSION_ID"
				PACKAGETYPE="zypper"
				;;
			opensuse-tumbleweed)
				OS="opensuse"
				VERSION="tumbleweed"
				PACKAGETYPE="zypper"
				;;
			sle-micro-rancher)
				OS="opensuse"
				VERSION="leap/15.4"
				PACKAGETYPE="zypper"
				;;
			arch|archarm|endeavouros|blendos|garuda|archcraft|cachyos)
				OS="arch"
				VERSION="" 
				PACKAGETYPE="pacman"
				;;
			manjaro|manjaro-arm|biglinux)
				OS="manjaro"
				VERSION=""
				PACKAGETYPE="pacman"
				;;
			alpine)
				OS="$ID"
				VERSION="$VERSION_ID"
				PACKAGETYPE="apk"
				;;
			postmarketos)
				OS="alpine"
				VERSION="$VERSION_ID"
				PACKAGETYPE="apk"
				;;
			nixos)
				echo "Please add Tailscale to your NixOS configuration directly:"
				echo "services.tailscale.enable = true;"
				exit 1
				;;
			bazzite)
				echo "Bazzite comes with Tailscale installed by default."
				echo "ujust enable-tailscale"
				echo "tailscale up"
				exit 1
				;;
			void)
				OS="$ID"
				VERSION=""
				PACKAGETYPE="xbps"
				;;
			gentoo)
				OS="$ID"
				VERSION=""
				PACKAGETYPE="emerge"
				;;
			freebsd)
				OS="$ID"
				VERSION="$VERSION_MAJOR"
				PACKAGETYPE="pkg"
				;;
			osmc)
				OS="debian"
				PACKAGETYPE="apt"
				VERSION="bullseye"
				APT_KEY_TYPE="keyring"
				;;
			photon)
				OS="photon"
				VERSION="$VERSION_MAJOR"
				PACKAGETYPE="tdnf"
				;;
			steamos)
				echo "To install Tailscale on SteamOS, please follow the instructions here:"
				echo "https://github.com/tailscale-dev/deck-tailscale"
				exit 1
				;;
		esac
	fi

	if [ -z "$OS" ]; then
		if type uname >/dev/null 2>&1; then
			case "$(uname)" in
				FreeBSD)
					OS="freebsd"
					VERSION="$(freebsd-version | cut -f1 -d.)"
					PACKAGETYPE="pkg"
					;;
				OpenBSD)
					OS="openbsd"
					VERSION="$(uname -r)"
					PACKAGETYPE=""
					;;
				Darwin)
					OS="macos"
					VERSION="$(sw_vers -productVersion | cut -f1-2 -d.)"
					PACKAGETYPE="appstore"
					;;
				Linux)
					OS="other-linux"
					VERSION=""
					PACKAGETYPE=""
					;;
			esac
		fi
	fi

	CURL=
	if type curl >/dev/null; then
		CURL="curl -fsSL"
	elif type wget >/dev/null; then
		CURL="wget -q -O-"
	fi
	if [ -z "$CURL" ]; then
		echo "The installer needs either curl or wget to download files."
		exit 1
	fi

	TEST_URL="https://pkgs.tailscale.com/"
	RC=0
	TEST_OUT=$($CURL "$TEST_URL" 2>&1) || RC=$?
	if [ $RC != 0 ]; then
		echo "The installer cannot reach $TEST_URL"
		echo "Please make sure that your machine has internet access."
		echo "Test output:"
		echo $TEST_OUT
		exit 1
	fi

	OS_UNSUPPORTED=
	case "$OS" in
		ubuntu|debian|raspbian|centos|oracle|rhel|amazon-linux|opensuse|photon)
			URL="https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/installer-supported"
			$CURL "$URL" 2> /dev/null | grep -q OK || OS_UNSUPPORTED=1
			;;
		fedora|arch|manjaro|alpine|void|gentoo)
			;;
		freebsd)
			if [ "$VERSION" != "12" ] && [ "$VERSION" != "13" ] && [ "$VERSION" != "14" ] && [ "$VERSION" != "15" ]; then
				OS_UNSUPPORTED=1
			fi
			;;
		openbsd|macos|other-linux|*)
			OS_UNSUPPORTED=1
			;;
	esac
	if [ "$OS_UNSUPPORTED" = "1" ]; then
		echo "Unsupported OS: $OS $VERSION"
		exit 1
	fi

	CAN_ROOT=
	SUDO=
	if [ "$(id -u)" = 0 ]; then
		CAN_ROOT=1
		SUDO=""
	elif type sudo >/dev/null; then
		CAN_ROOT=1
		SUDO="sudo"
	elif type doas >/dev/null; then
		CAN_ROOT=1
		SUDO="doas"
	fi
	if [ "$CAN_ROOT" != "1" ]; then
		echo "This installer needs to run commands as root."
		exit 1
	fi

	OSVERSION="$OS"
	[ "$VERSION" != "" ] && OSVERSION="$OSVERSION $VERSION"

	PACKAGE_NAME="tailscale"
	echo "Installing Tailscale for $OSVERSION, using method $PACKAGETYPE"
	
	case "$PACKAGETYPE" in
		apt)
			export DEBIAN_FRONTEND=noninteractive
			if [ "$APT_KEY_TYPE" = "legacy" ] && ! type gpg >/dev/null; then
				$SUDO apt-get update
				$SUDO apt-get install -y gnupg
			fi

			set -x
			$SUDO mkdir -p --mode=0755 /usr/share/keyrings
			case "$APT_KEY_TYPE" in
				legacy)
					$CURL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION.asc" | $SUDO apt-key add -
					$CURL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION.list" | $SUDO tee /etc/apt/sources.list.d/tailscale.list
					$SUDO chmod 0644 /etc/apt/sources.list.d/tailscale.list
				;;
				keyring)
					$CURL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION.noarmor.gpg" | $SUDO tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
					$SUDO chmod 0644 /usr/share/keyrings/tailscale-archive-keyring.gpg
					$CURL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION.tailscale-keyring.list" | $SUDO tee /etc/apt/sources.list.d/tailscale.list
					$SUDO chmod 0644 /etc/apt/sources.list.d/tailscale.list
				;;
			esac
			$SUDO apt-get update
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO apt-get install -y "tailscale=$TAILSCALE_VERSION" tailscale-archive-keyring
			else
				$SUDO apt-get install -y tailscale tailscale-archive-keyring
			fi
			if [ "$APT_SYSTEMCTL_START" = "true" ]; then
				$SUDO systemctl enable --now tailscaled
				$SUDO systemctl start tailscaled
			fi
			set +x
		;;
		yum)
			set -x
			$SUDO yum install yum-utils -y
			$SUDO yum-config-manager -y --add-repo "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo"
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO yum install "tailscale-$TAILSCALE_VERSION" -y
			else
				$SUDO yum install tailscale -y
			fi
			$SUDO systemctl enable --now tailscaled
			set +x
		;;
		dnf)
			DNF_VERSION="3"
			if LANG=C.UTF-8 dnf --version | grep -q '^dnf5 version'; then
				DNF_VERSION="5"
			fi
			if [ "$DNF_VERSION" = "5" ]; then
				set -x
				$SUDO dnf install -y 'dnf-command(config-manager)' && DNF_HAVE_CONFIG_MANAGER=1 || DNF_HAVE_CONFIG_MANAGER=0
				set +x
				if [ "$DNF_HAVE_CONFIG_MANAGER" != "1" ]; then
					if type dnf-3 >/dev/null; then
						DNF_VERSION="3"
					else
						echo "dnf 5 detected, but 'dnf-command(config-manager)' not available"
						exit 1
					fi
				fi
			fi

			set -x
			if [ "$DNF_VERSION" = "3" ]; then
				$SUDO dnf install -y 'dnf-command(config-manager)'
				$SUDO dnf config-manager --add-repo "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo"
			elif [ "$DNF_VERSION" = "5" ]; then
				$SUDO dnf config-manager addrepo --from-repofile="https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo"
			fi
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO dnf install -y "tailscale-$TAILSCALE_VERSION"
			else
				$SUDO dnf install -y tailscale
			fi
			$SUDO systemctl enable --now tailscaled
			set +x
		;;
		tdnf)
			set -x
			curl -fsSL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo" > /etc/yum.repos.d/tailscale.repo
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO tdnf install -y "tailscale-$TAILSCALE_VERSION"
			else
				$SUDO tdnf install -y tailscale
			fi
			$SUDO systemctl enable --now tailscaled
			set +x
		;;
		zypper)
			set -x
			$SUDO rpm --import "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/repo.gpg"
			$SUDO zypper --non-interactive ar -g -r "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo"
			$SUDO zypper --non-interactive --gpg-auto-import-keys refresh
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO zypper --non-interactive install "tailscale=$TAILSCALE_VERSION"
			else
				$SUDO zypper --non-interactive install tailscale
			fi
			$SUDO systemctl enable --now tailscaled
			set +x
			;;
		pacman)
			set -x
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO pacman -S "tailscale=$TAILSCALE_VERSION" --noconfirm
			else
				$SUDO pacman -S tailscale --noconfirm
			fi
			$SUDO systemctl enable --now tailscaled
			set +x
			;;
		pkg)
			set -x
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO pkg install --yes "tailscale-$TAILSCALE_VERSION"
			else
				$SUDO pkg install --yes tailscale
			fi
			$SUDO service tailscaled enable
			$SUDO service tailscaled start
			set +x
			;;
		apk)
			set -x
			if ! grep -Eq '^http.*/community$' /etc/apk/repositories; then
				if type setup-apkrepos >/dev/null; then
					$SUDO setup-apkrepos -c -1
				else
					echo "community repo required in /etc/apk/repositories"
					exit 1
				fi
			fi
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO apk add "tailscale=$TAILSCALE_VERSION"
			else
				$SUDO apk add tailscale
			fi
			$SUDO rc-update add tailscale
			$SUDO rc-service tailscale start
			set +x
			;;
		xbps)
			set -x
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO xbps-install "tailscale-$TAILSCALE_VERSION" -y
			else
				$SUDO xbps-install tailscale -y
			fi
			set +x
			;;
		emerge)
			set -x
			if [ -n "$TAILSCALE_VERSION" ]; then
				$SUDO emerge --ask=n "=net-vpn/tailscale-$TAILSCALE_VERSION"
			else
				$SUDO emerge --ask=n net-vpn/tailscale
			fi
			set +x
			;;
		appstore)
			set -x
			open "https://apps.apple.com/us/app/tailscale/id1475387142"
			set +x
			;;
		*)
			echo "unexpected: unknown package type $PACKAGETYPE"
			exit 1
			;;
	esac

	echo ""
	echo "#######################################################"
	echo "#      INSTALASI SELESAI - AUTO QR STARTING...        #"
	echo "#######################################################"
	echo ""
	
	# Bagian Modifikasi: Menjalankan Tailscale Up dengan QR Code
	echo "Menyiapkan QR Code untuk login..."
	if [ -z "$SUDO" ]; then
		tailscale up --qr
	else
		$SUDO tailscale up --qr
	fi
}

main
