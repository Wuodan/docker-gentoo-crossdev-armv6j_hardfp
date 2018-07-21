FROM wuodan/gentoo-crossdev

ARG TARGET=armv6j-hardfloat-linux-gnueabi

# create toolchain
RUN crossdev --stable -t "${TARGET}"

# copy the entire stage3 volume to crossdev target
COPY stage3-armv6j_hardfp-20180421.tar.bz2.part.* /tmp/

# join the stage3 tar.bz2
RUN cat /tmp/stage3-armv6j_hardfp-20180421.tar.bz2.part.* > /tmp/stage3-armv6j_hardfp-20180421.tar.bz2 && \
	tar xpf /tmp/stage3-armv6j_hardfp-20180421.tar.bz2 --xattrs-include='*.*' --numeric-owner -C /usr/${TARGET}/ && \
	rm /tmp/stage3-armv6j_hardfp-20180421.tar.bz2*

# set target make.conf
COPY make.conf.arm /usr/${TARGET}/etc/portage/make.conf

# set target make profile
RUN cd /usr/${TARGET}/etc/portage && \
	rm make.profile && \
	ln -s /usr/portage/profiles/default/linux/arm/13.0/armv6j make.profile && \
	\
# add symlink to lib64, see https://wiki.gentoo.org/wiki/Cross_build_environment#Known_bugs_and_limitations
	cd /usr/${TARGET}/usr && \
	ln -s lib lib64

# this will contain failures, gcc fails for sure
RUN armv6j-hardfloat-linux-gnueabi-emerge -uv --keep-going --exclude "sys-apps/file sys-apps/util-linux sys-devel/gcc" world || exit 0

RUN QEMU_USER_TARGETS="arm" QEMU_SOFTMMU_TARGETS="arm" USE="static-user static-libs" emerge -q --buildpkg --oneshot qemu
RUN cd "/usr/${TARGET}" && \
	ROOT=$PWD/ emerge -q --usepkgonly --oneshot --nodeps qemu

COPY chroot-armv6j /usr/local/bin/
RUN chmod +x /usr/local/bin/chroot-armv6j

# CMD chroot-armv6j
# CMD ln -s /tmp /usr/armv6j-hardfloat-linux-gnueabi/tmp
# CMD cat /etc/locale.gen
# CMD cat /etc/env.d/02locale
# CMD date
# CMD gcc-config -l;ldconfig -v;ROOT=/ env-update; source /etc/profile
# CMD echo 'alias emerge-chroot="ROOT=/ CBUILD=$(grep CHOST= /etc/portage/make.conf|cut -d= -f2) HOSTCC=$CBUILD emerge"' > /etc/bash/bashrc.d/emerge-chroot && source /etc/profile
# CMD emerge-chroot --ask --update -v --keep-going @system

## RUN armv6j-hardfloat-linux-gnueabi-emerge -uv --keep-going -1 sys-devel/binutils sys-libs/glibc sys-devel/gcc
# RUN armv6j-hardfloat-linux-gnueabi-emerge -uv --keep-going -1 portage
