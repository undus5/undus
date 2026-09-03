+++
title       = "Snippets"
date        = 2024-11-25
weight      = 9900
hidden      = true
+++

SVG to PNG

Fedora package: `librsvg2-tools`

```
(user)$ rsvg-convert -w 800 input.svg > output.png
```

Android WiFi "Limited Connection"

```
(user)$ adb shell
(user)$ settings put global captive_portal_https_url https://httpstat.us/204
(user)$ settings put global captive_portal_http_url http://httpstat.us/204
```

Extend Library PATH

```
(user)$ LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH <command ...>
```

File Encoding

```
# unzip with specific encoding
(user)$ unzip -O GB18030 <filename> -d <target_dir>

# convert txt encoding
(user)$ iconv -f GB18030 -t UTF-8 < in.txt > out.txt

# urlencode
(user)$ echo "example text" | perl -MURI::Escape -lne 'print uri_escape($_)'
```

Extract .z01

```
(user)$ 7z x example.z01
```

Recursively Change Files and Directories

```
# change permissin
(user)$ find . -type d -exec chmod 755 {} \;
(user)$ find . -type f -exec chmod 644 {} \;

# rename files (rename.ul)
(user)$ find . -type f -name "foo*" -exec rename foo bar {} \;

# rename files (prename)
(user)$ find . -type f -name "foo*" -exec rename 's/foo/bar' '{}' \;
```

