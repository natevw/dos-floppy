#! /bin/bash

set -e
set -o pipefail

: ${1?"Pass parent directory as first argument!"}
imgdir=$1
outdir=${2:-$imgdir}

# result="image"
result="zipfile"
# result="folder"


samdisk()
{
  "${HOME}/Downloads/samdisk-388-osx/samdisk" "$@"
}

attach()
{
  hdiutil attach "$img_mac_ext" -plist |
  plutil -extract system-entities.0.mount-point binary1 -o - - |
  plutil -p - |
  sed 's/^"\(.*\)"$/\1/'
}

for fluxfile in "$imgdir"/*.scp; do
  [ -e "$fluxfile" ] || continue    # avoid nullglob
  
  name=$(basename "$fluxfile" .scp)
  
  echo "Processing '${name}'"
  # SAMdisk uses .raw extension for image output
  # (see https://simonowen.com/samdisk/formats/)
  # macOS uses .img extension for this format
  img_sam_ext="${outdir}/${name}.raw"
  img_mac_ext="${outdir}/${name}.img"
  
  samdisk copy "$fluxfile" "$img_sam_ext"
  mv "$img_sam_ext" "$img_mac_ext"
  
  if [ "$result" = "image" ]; then
    continue
  fi
  
  mounted_img=$(attach "$img_mac_ext")
  echo "mi: $? $mounted_img"
  #ls -l "$mounted_img"
  
  if [ "$result" = "zipfile" ]; then
    (
      cd "$mounted_img"
      # HT: https://superuser.com/a/1347640/148918
      zip - -r . > "${outdir}/${name}.zip"
    )
  elif [ "$result" = "folder" ]; then
    mkdir -p "${outdir}/${name}"
    cp -R "$mounted_img/" "${outdir}/${name}"
  fi
  
  hdiutil detach "$mounted_img"
  if [ "$result" != "image" ]; then
    rm "$img_mac_ext"
  fi
done

