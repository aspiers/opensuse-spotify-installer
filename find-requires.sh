#!/bin/sh

/usr/lib/rpm/find-requires | \
    sed -e 's/lib\(nss3\|nssutil3\|smime3\|plc4\|nspr4\)\.so\.[01]d/lib\1.so/
            /lib\(crypto\|ssl\)\.so/d'
