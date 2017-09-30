
# Determine Linux dist and version:
if [ -f "/etc/os-release" ]; then
  # Debian 8+, Ubuntu 14+, CentOS 7+, RHEL 7+
  dist_name="$(cat /etc/os-release | grep ^ID\= | sed "s|\"||g" | awk -F\= '{print tolower($2)}')"
  dist_vers="$(cat /etc/os-release | grep ^VERSION_ID\= | sed "s|\"||g" | awk -F\= '{print tolower($2)}' | awk -F. '{print $1}')"
elif [ -f "/etc/system-release-cpe" ]; then
# CentOS 6, RHEL 6
  dist_name="$(cat /etc/system-release-cpe | awk -F':' '{print tolower($3)}')"
  if [ "$dist_name" == "redhat" ]; then
     dist_name="rhel" # Correction for RHEL 6
  fi
  dist_vers="$(cat /etc/system-release-cpe | awk -F':' '{print tolower($5)}' | sed "s|server||g" | awk -F. '{print $1}')"
fi
dist_name_and_vers="$dist_name-$dist_vers"
echo dist_name_and_vers
echo $dist_name_and_vers


# Determine packaging tools:
which apt
if [ "$dist_name_and_vers" == "0" ]; then
   pkg_tools="apt"
else
   which yum
   if [ "$?" == "0" ]; then
       pkg_tools="yum"
   fi
fi

# Define packages based on dist/version:
if [ "$dist_name" == "ubuntu" ]; then
   if [ "$dist_vers" == "14.04" ]; then
        declare -a PKG_LIST=(python-google-compute-engine google-compute-engine-oslogin)
   else
        declare -a PKG_LIST=(python-google-compute-engine python3-google-compute-engine google-compute-engine-oslogin)
   fi
elif [ "$dist_name" == "debian" ]; then
   declare -a PKG_LIST=(google-cloud-packages-archive-keyring python-google-compute-engine python3-google-compute-engine google-compute-engine)
elif ( [ "$dist_name" == "centos" ] || [ "$dist_name" == "rhel" ] ); then
   declare -a PKG_LIST=(python-google-compute-engine.noarch google-compute-engine.noarch)
fi

# Download tools and packages:
pkg_output_dir="/tmp/lge_pkgs_$dist_name_and_vers"
mkdir -p "$pkg_output_dir"
cd "$pkg_output_dir"

if [ "$pkg_tools" == "apt" ]; then
   # Debian flavors...
   # See https://linux.die.net/man/8/aptitude.
   apt-get -y update
   apt-get -y upgrade
   apt install -y aptitude
   for pkg in "${PKG_LIST[@]}"; do
       aptitude download "$pkg"
   done
   # Rename files for installation order:
   for file_name in $(ls .); do
       new_name="$(echo $file_name | sed "s|python|00-python|")"
       if [ "$file_name" != "new_name" ]; then
          mv $file_name $new_name
       fi
   done

elif [ "$pkg_tools" == "yum" ]; then
   # RHEL flavors...
   # See https://access.redhat.com/solutions/10154.
   # See https://linux.die.net/man/1/yumdownloader.
   yum -y update
   yum -y upgrade
   yum -y install yum-utils
   for pkg in "${PKG_LIST[@]}"; do
       yumdownloader "$pkg"
   done
   # Rename files for installation order:
   for file_name in $(ls .); do
       IFS="-" eval 'file_name_array=($file_name)'
       new_name="$(echo ${file_name_array[@]:1} | sed "s| |-|g" | sed "s|python|00-python|")"
       if [ "$file_name" != "new_name" ]; then
          mv $file_name $new_name
       fi
   done
fi