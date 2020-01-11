#!/bin/bash

## Sanity Checks and automagic
function root-check() {
if [[ "$EUID" -ne 0 ]]; then
  echo "Sorry, you need to run this as root"
  exit
fi
}

## Root Check
root-check

function dist-check() {
  if [ -e /etc/centos-release ]; then
    DISTRO="CentOS"
  elif [ -e /etc/debian_version ]; then
    DISTRO=$( lsb_release -is )
  elif [ -e /etc/fedora-release ]; then
    DISTRO="Fedora"
  elif [ -e /etc/redhat-release ]; then
    DISTRO="Redhat"
  else
    echo "Your distribution is not supported (yet)."
    exit
  fi
}

## Check distro
dist-check

## Start Installation Of Packages
function install-essentials() {
  if [ "$DISTRO" == "Ubuntu" ]; then
  apt-get update
  apt-get install webp inotify-tools wget -y
  elif [ "$DISTRO" == "Ubuntu" ]; then
  apt-get update 
  apt-get install webp inotify-tools wget -y
  elif [ "$DISTRO" == "CentOS" ]; then
  yum update 
  yum install webp inotify-tools wget -y
fi
}

## Script to convert images
function install-convert-script() {
    echo "#!/bin/bash
# converting JPEG images
find $1 -type f -and \( -iname "*.jpg" -o -iname "*.jpeg" \) \
-exec bash -c '
webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
if [ ! -f "$webp_path" ]; then 
  cwebp -quiet -q 90 "$0" -o "$webp_path";
fi;' {} \;
# converting PNG images
find $1 -type f -and -iname "*.png" \
-exec bash -c '
webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
if [ ! -f "$webp_path" ]; then 
  cwebp -quiet -lossless "$0" -o "$webp_path";
fi;' {} \;" >> /tmp/webp-convert.sh

chmod a+x /tmp/webp-convert.sh

}

## Run the function
install-convert-script


function install-watch-script() {
echo "#!/bin/bash
echo "Setting up watches.";
# watch for any created, moved, or deleted image files
inotifywait -q -m -r --format '%e %w%f' -e close_write -e moved_from -e moved_to -e delete $1 \
| grep -i -E '\.(jpe?g|png)$' --line-buffered \
| while read operation path; do
  webp_path="$(sed 's/\.[^.]*$/.webp/' <<< "$path")";
  if [ $operation = "MOVED_FROM" ] || [ $operation = "DELETE" ]; then # if the file is moved or deleted
    if [ -f "$webp_path" ]; then
      $(rm -f "$webp_path");
    fi;
  elif [ $operation = "CLOSE_WRITE,CLOSE" ] || [ $operation = "MOVED_TO" ]; then  # if new file is created
     if [ $(grep -i '\.png$' <<< "$path") ]; then
       $(cwebp -quiet -lossless "$path" -o "$webp_path");
     else
       $(cwebp -quiet -q 90 "$path" -o "$webp_path");
     fi;
  fi;
done;" >> /tmp/webp-watchers.sh

chmod a+x /tmp/webp-watchers.sh
}


## Run The Function
install-watch-script

function install-rewrite() {
echo "<ifModule mod_rewrite.c>
  RewriteEngine On 
  RewriteCond %{HTTP_ACCEPT} image/webp
  RewriteCond %{REQUEST_URI}  (?i)(.*)(\.jpe?g|\.png)$ 
  RewriteCond %{DOCUMENT_ROOT}%1.webp -f
  RewriteRule (?i)(.*)(\.jpe?g|\.png)$ %1\.webp [L,T=image/webp,R] 
</IfModule>
<IfModule mod_headers.c>
  Header append Vary Accept env=REDIRECT_accept
</IfModule>
AddType image/webp .webp" >> /tmp/.htaccess
}

install-rewrite

## Function to find and remove all images. (Not Recommended.)
function find-remove() {
    find . -name "*.png" -type f -delete
    find . -name "*.jpg" -type f -delete
    find . -name "*.jpeg" -type f -delete
}
