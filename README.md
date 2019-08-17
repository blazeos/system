docker run -it --mount type=bind,source=/opt/sysroot,target=/opt/sysroot --rm debian:buster /bin/bash -c "apt-get update; apt-get install -y git; cd /opt; git clone https://github.com/blazeos/system.git; bash"

time bash system/scripts/build_arm.sh

##Create arm64 environment

/scripts/create_aarch64_env.sh
