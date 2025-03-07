# kdump for Ubuntu

## Obtaining an kdump

Use the `ubuntu-enable-kdump.yaml` DaemonSet to install and setup kdump on a set
of nodes. The DaemonSet uses the `enable-kdump=true` node selector, so nodes
must be labeled

```
kubectl label nodes ${NODE_NAME} enable-kdump=true
```

## Triggering a test kdump

SSH into a node and trigger a system crash with sysrq

```
sudo -i
sysctl -w kernel.sysrq=1
echo c > /proc/sysrq-trigger
```

A dump will be written to `/var/crash`

## Analyzing an kdump

Create a VM for the analysis

```
gcloud beta compute instances create dump-test-vm \
--machine-type=e2-standard-4 \
--image-family=ubuntu-1804-lts \
--image-project=ubuntu-os-cloud \
--boot-disk-size=100GB \
--boot-disk-type=pd-ssd \
--zone=us-central1-c
```

SCP the contents of `/var/crash` to dump-test-vm

Find the right deb for the correct kernel version, see
[here](https://launchpad.net/~canonical-kernel-team/+archive/ubuntu/ppa/+packages?field.name_filter=linux-gke&field.status_filter=published).
Obtain the url for the deb for the linux image with debug symbols, e.g. for
`linux-gke-5.0 - 5.0.0-1046.47` the deb containing the vmlinux can be obtained
[here](https://launchpad.net/~canonical-kernel-team/+archive/ubuntu/ppa/+build/18789932/+files/linux-image-unsigned-5.0.0-1032-gke-dbgsym_5.0.0-1032.33_amd64.ddeb).

```
gcloud compute ssh dump-test-vm
sudo apt-get update && sudo apt-get install -y linux-crashdump

cd ${HOME}
# Location of deb for vmlinux
LINUX_DEB_IMAGE_URL="https://launchpad.net/..."
wget "${LINUX_DEB_IMAGE_URL}"
ar -x linux-image-unsigned-5.0.0-1032-gke-dbgsym_5.0.0-1032.33_amd64.ddeb
mkdir debug_image
tar -xf data.tar.xz -C debug_image/

# Contents of /var/crash from the crash dump.
CRASH_DUMP="var/crash/SOME_TIMESTAMP/dump.SOME_TIMESTAMP"

# Start debugging!
crash debug_image/usr/lib/debug/boot/vmlinux-5.0.0-1032-gke ${CRASH_DUMP}
```
