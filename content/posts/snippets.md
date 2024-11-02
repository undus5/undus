+++
title       = "Snippets"
showSummary = true
weight      = 9900
+++

Useful commands.

<!--more-->

Write protecting file

```shell
sudo chattr +i data.txt
sudo chattr -i data.txt
```

Android WiFi "Limited Connection"

```shell
adb shell

settings put global captive_portal_https_url https://httpstat.us/204
settings put global captive_portal_http_url http://httpstat.us/204
```

Extend Library PATH

```shell
# add dir to library PATH
export LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH

# list files in RPM
rpm -qlp example.rpm

# extract files from RPM
rpm2cpio example.rpm | cpio -idmv
```

Image Converting

```shell
# install ImageMagick
sudo dnf install ImageMagick

# convert and resize image
convert -scale 800x input.jpg output.webp

# convert image to grayscale
convert -colorspace gray input.jpg output.jpg

# convert transparent image to white background
convert -background white -flatten input.png output.jpg
```

File Encoding

```shell
# unzip with specific encoding
unzip -O GB18030 <filename> -d <target_dir>

# convert txt encoding
iconv -f GB18030 -t UTF-8 < in.txt > out.txt

# urlencode
echo "example text" | perl -MURI::Escape -lne 'print uri_escape($_)'
```

Extract .z01

```shell
7z x example.z01
```

Recursively Change Files and Directories

```shell
# change permissin
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

# rename files (rename.ul)
find . -type f -name "foo*" -exec rename foo bar {} \;

# rename files (prename)
find . -type f -name "foo*" -exec rename 's/foo/bar' '{}' \;
```

Git 

```shell
# remove untracked files
git clean -f -d

# force to use LF (Windows)
git config --global core.autocrlf input
git config --global core.eol lf
```

Remove Large Directory

```shell
mkdir tmp
rsync -a --delete tmp large_dir
rm -rf tmp
```
