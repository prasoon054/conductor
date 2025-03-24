#!/bin/bash

SIMPLE_CONTAINER_ROOT=container_root

mkdir -p $SIMPLE_CONTAINER_ROOT

gcc -o container_prog container_prog.c

## Subtask 1: Execute in a new root filesystem

cp container_prog $SIMPLE_CONTAINER_ROOT/

# 1.1: Copy any required libraries to execute container_prog to the new root container filesystem 
mkdir -p $SIMPLE_CONTAINER_ROOT/lib64
# cp -v /bin/{bash,touch,ls,rm} $SIMPLE_CONTAINER_ROOT/bin
cp container_prog $SIMPLE_CONTAINER_ROOT
list="$(ldd container_prog | egrep -o '/lib.*\.[0-9]')"
for i in $list; do cp --parents "$i" "${SIMPLE_CONTAINER_ROOT}"; done

echo -e "\n\e[1;32mOutput Subtask 2a\e[0m"
# 1.2: Execute container_prog in the new root filesystem using chroot. You should pass "subtask1" as an argument to container_prog
chroot $SIMPLE_CONTAINER_ROOT ./container_prog subtask1


echo "__________________________________________"
echo -e "\n\e[1;32mOutput Subtask 2b\e[0m"
## Subtask 2: Execute in a new root filesystem with new PID and UTS namespace
# The pid of container_prog process should be 1
# You should pass "subtask2" as an argument to container_prog
unshare --uts --pid --fork --mount-proc -r chroot $SIMPLE_CONTAINER_ROOT ./container_prog subtask2


echo -e "\nHostname in the host: $(hostname)"

## Subtask 3: Execute in a new root filesystem with new PID, UTS and IPC namespace + Resource Control
# Create a new cgroup and set the max CPU utilization to 50% of the host CPU. (Consider only 1 CPU core)
CGROUP_PATH="/sys/fs/cgroup/simple_container"
mkdir -p $CGROUP_PATH
echo "50000 100000" > /sys/fs/cgroup/simple_container/cpu.max


echo "__________________________________________"
echo -e "\n\e[1;32mOutput Subtask 2c\e[0m"
# Assign pid to the cgroup such that the container_prog runs in the cgroup
# Run the container_prog in the new root filesystem with new PID, UTS and IPC namespace
# You should pass "subtask1" as an argument to container_prog
unshare --uts --pid --fork --mount-proc -r bash -c "echo \$\$ > $CGROUP_PATH/cgroup.procs; exec chroot $SIMPLE_CONTAINER_ROOT ./container_prog subtask3"

# Remove the cgroup
rmdir $CGROUP_PATH

# If mounted dependent libraries, unmount them, else ignore
