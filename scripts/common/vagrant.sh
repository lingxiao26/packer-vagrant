#!/bin/sh

set -e
set -x

date | tee /etc/vagrant_box_build_time

mkdir -p ~/.ssh
cat <<EOF >>~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAswzlAEyWQzBaE7WESi9E9OJeTBKCh5ysRWTHNVWw/CpjxnN2KDm5Q6DKIeWYeMRUUmWC+aHFECs23OxVf0HISkCM623jsGoBUCN0Sh9rZyyN0leKiTEXGxaFf6oriQZ9v4CHuGZkm4dZmNzgfB06E/EA8e+tSZh0QB2XfKJxFxSf27BCn/uyuy5Bidk6HFWqTdNAY8+j9BJeo48j1RlBmBIAVtERTpLQ8CAKbGXM/1DFtftn+rm7RFULDdbhzOUd/Z4SibEPLKmvLdp3bMlNVK/F401X1+5gR1A5zYTlAmu9y9hGs0fHM8rglv458HlnPlQq2EPaBvXklvrR6yhVUQ== li.lingxiao
EOF
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/authorized_keys
