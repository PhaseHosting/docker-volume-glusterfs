

################################################################################

PROGRAM             = docker-volume-glusterfs
PACKAGE             = $(PROGRAM)

BUILD               = $(shell git rev-parse HEAD)

PLATFORMS           = linux_amd64 linux_386 linux_arm darwin_amd64 freebsd_amd64 freebsd_386
PLATFORMS_TAR       = linux_amd64 linux_386 linux_arm darwin_amd64 freebsd_amd64 freebsd_386
PLATFORMS_DEB       = linux_amd64 linux_386 linux_arm
CURRENT_PLATFORM    = $(shell go env GOOS)_$(shell go env GOARCH)

FLAGS_all           = GOPATH=$(GOPATH)
FLAGS_linux_amd64   = $(FLAGS_all) GOOS=linux GOARCH=amd64
FLAGS_linux_386     = $(FLAGS_all) GOOS=linux GOARCH=386
FLAGS_linux_arm     = $(FLAGS_all) GOOS=linux GOARCH=arm
FLAGS_darwin_amd64  = $(FLAGS_all) GOOS=darwin GOARCH=amd64
FLAGS_freebsd_amd64 = $(FLAGS_all) GOOS=freebsd GOARCH=amd64
FLAGS_freebsd_386   = $(FLAGS_all) GOOS=freebsd GOARCH=386

msg=@printf "\n\033[0;01m>>> %s\033[0m\n" $1


################################################################################


.DEFAULT_GOAL := build

build: guard-VERSION deps
	$(call msg,"Build binary")
	$(FLAGS_all) go build -ldflags "-X main.Version=${VERSION} -X main.Build=${BUILD}" -o docker-volume-glusterfs$(EXTENSION_$GOOS_$GOARCH) *.go
	./docker-volume-glusterfs -version
.PHONY: build

deps:
	$(call msg,"Get dependencies")
	go get -t ./...
	go get -d github.com/Sirupsen/logrus
	go get -d github.com/coreos/go-systemd/activation
	go get -d github.com/opencontainers/runc/libcontainer/user
.PHONY: deps

lint:
	$(call msg,"Linting source code")
	go get github.com/golang/lint/golint
	golint 
	$(call msg,"Linting CI config")
	build/lint-ci.sh
#	probably requires 'apt-get install lintian'
#	$(call msg,"Linting Debian Packages")
#	lintian
.PHONY: lint

# install the current OS & architecture
install: guard-VERSION deps install/$(CURRENT_PLATFORM)
.PHONY: install

uninstall:
	$(call msg,"Uninstall docker-volume-glusterfs")
	# Don't delete the configuration files in etc. That's not nice.
	rm -f $(DESTDIR)/usr/sbin/$(PROGRAM)
	rm -f $(DESTDIR)/lib/systemd/system/$(PROGRAM).service
	rm -Rf $(DESTDIR)/usr/share/doc/$(PROGRAM)
.PHONY:	uninstall

test: deps
	$(call msg,"Run tests")
	$(FLAGS_all) go test $(wildcard ../*.go)
.PHONY: test

clean:
	$(call msg,"Clean directory")
	rm -f docker-volume-glusterfs
	rm -rf dist
.PHONY: clean

build-all: deps guard-VERSION $(foreach PLATFORM,$(PLATFORMS),dist/$(PLATFORM)/.built)
.PHONY: build-all

dist: guard-VERSION build-all \
$(foreach PLATFORM,$(PLATFORMS_TAR),dist/docker-volume-glusterfs-$(VERSION)-$(PLATFORM).tar.gz)
.PHONY:	dist

release: guard-VERSION dist
	$(call msg,"Create and push release")
	git tag -a "v$(VERSION)" -m "Release $(VERSION)"
	git push --tags
.PHONY: tag-release

package: build-all \
$(foreach PLATFORM,$(PLATFORMS_DEB),dist/$(PLATFORM)/.deb)
.PHONY: package

################################################################################

install/%: dist/%/.built
	$(call msg,"Install $(PROGRAM)")
	install -D dist/$*/docker-volume-glusterfs $(DESTDIR)/usr/sbin/$(PROGRAM)
	install -D init-systems/systemd/etc/systemd/system/docker-volume-glusterfs.service $(DESTDIR)/lib/systemd/system/$(PROGRAM).service
	install -D init-systems/systemd/etc/docker-volume-glusterfs.conf $(DESTDIR)/etc/$(PROGRAM).conf
	install -D init-systems/upstart/etc/default/docker-volume-glusterfs $(DESTDIR)/etc/default/$(PROGRAM)
	install -D init-systems/upstart/etc/init/docker-volume-glusterfs.conf $(DESTDIR)/etc/init/$(PROGRAM).conf
	install -D LICENSE $(DESTDIR)/usr/share/doc/$(PROGRAM)/copyright
.PHONY:	install/%

# needs FPM
# apt-get install ruby ruby-dev && gem install -N fpm
# TODO: figure out how to deploy
# TODO: figure out how to specify architecture right
dist/%/.deb: dist/%/.built
	$(call msg,"Build Debian package for $*")
	fpm -s dir -t deb -n $(PACKAGE) -v $(VERSION) \
		--license LICENSE \
		--category TODO \
		--depends 'docker-engine' \
		--depends 'glusterfs-client (>= 3.5.0)' \
		--depends 'glusterfs-client (<< 3.7.0)' \
		--depends 'systemd' \
		--architecture native \
		--maintainer 'Patrick Watson <TODO>' \
		--description 'This package provides the ability for docker to mount glusterfs volumes.' \
		--url 'http://github.com/watson81/docker-volume-glusterfs' \
		--deb-priority optional \
		--deb-default init-systems/upstart/etc/default/docker-volume-glusterfs \
		--deb-upstart init-systems/upstart/etc/init/docker-volume-glusterfs.conf \
		--deb-systemd init-systems/systemd/etc/systemd/system/docker-volume-glusterfs.service \
		dist/$*/docker-volume-glusterfs=/usr/sbin/$(PROGRAM) \
		init-systems/systemd/etc/docker-volume-glusterfs.conf=/etc/$(PROGRAM).conf \
		LICENSE=/usr/share/doc/$(PROGRAM)/copyright
	mv *.deb $(dir $@)
	touch $@

dist/%/.built:
	$(call msg,"Build binary for $*")
	rm -f $@
	mkdir -p $(dir $@)
	$(FLAGS_$*) go build -ldflags "-X main.Version=${VERSION} -X main.Build=${BUILD}" -o dist/$*/docker-volume-glusterfs$(EXTENSION_$*) $(wildcard ../*.go)
	cp LICENSE $(dir $@)
	touch $@

dist/docker-volume-glusterfs-$(VERSION)-%.tar.gz:
	$(call msg,"Create TAR for $*")
	rm -f $@
	mkdir -p $(dir $@)
	tar czf $@ -C dist/$* --exclude=.built --exclude=*.deb .

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi


################################################################################
