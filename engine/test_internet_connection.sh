#!/bin/bash -e

curl -s --connect-timeout 10 -o /dev/null http://www.google.com/ncr \
    && curl -s --connect-timeout 10 -o /dev/null https://www.google.com/ncr || {
    cat <<EOF >&2
Cannot download from the Internet.
EOF
    false
}
