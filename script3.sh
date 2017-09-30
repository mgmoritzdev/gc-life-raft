

sudo cp -R /tmp/lge_pkgs_* /tmp/problematic-instance-new-disk/tmp/lge_pkgs

sudo chroot /tmp/problematic-instance-new-disk

cd /tmp/lge_pkgs

# Determine installer tool:
which dpkg
if [ "$?" == "0" ]; then
   installer_tool="dpkg"
else
   which rpm
   if [ "$?" == "0" ]; then
       installer_tool="rpm"
   fi
fi

for pkg in $(ls .); do
   "$installer_tool" -i "$pkg"
done

exit #Required so you leave the chroot!

