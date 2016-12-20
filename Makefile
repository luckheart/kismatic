# Set the build version
ifeq ($(origin VERSION), undefined)
	VERSION := $(shell git rev-parse --short HEAD)
endif

# Setup some useful vars
HOST_GOOS = $(shell go env GOOS)
HOST_GOARCH = $(shell go env GOARCH)
GLIDE_VERSION = v0.11.1
ifeq ($(origin GLIDE_GOOS), undefined)
	GLIDE_GOOS := $(HOST_GOOS)
endif
ifeq ($(origin GOOS), undefined)
	GOOS := $(HOST_GOOS)
endif

build: vendor
	go build -o bin/kismatic -ldflags "-X main.version=$(VERSION)" ./cmd/kismatic
	GOOS=linux go build -o bin/inspector/linux/$(HOST_GOARCH)/kismatic-inspector ./cmd/kismatic-inspector
	GOOS=darwin go build -o bin/inspector/darwin/$(HOST_GOARCH)/kismatic-inspector ./cmd/kismatic-inspector

clean:
	rm -rf bin
	rm -rf out
	rm -rf vendor
	rm -rf vendor-ansible/out
	rm -rf vendor-cfssl/out
	rm -rf vendor-provision/out

test: vendor
	go test ./cmd/... ./pkg/... $(TEST_OPTS)

integration-test: dist just-integration-test

vendor: tools/glide
	./tools/glide install

tools/glide:
	mkdir -p tools
	curl -L https://github.com/Masterminds/glide/releases/download/$(GLIDE_VERSION)/glide-$(GLIDE_VERSION)-$(GLIDE_GOOS)-$(HOST_GOARCH).tar.gz | tar -xz -C tools
	mv tools/$(GLIDE_GOOS)-$(HOST_GOARCH)/glide tools/glide
	rm -r tools/$(GLIDE_GOOS)-$(HOST_GOARCH)

vendor-ansible/out:
	docker build -t apprenda/vendor-ansible vendor-ansible
	docker run --rm -v $(shell pwd)/vendor-ansible/out:/ansible apprenda/vendor-ansible pip install --install-option="--prefix=/ansible" ansible==2.1.2.0

vendor-cfssl/out:
	mkdir -p vendor-cfssl/out/
	curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o vendor-cfssl/out/cfssl_linux-amd64
	curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o vendor-cfssl/out/cfssljson_linux-amd64
	curl -L https://pkg.cfssl.org/R1.2/cfssl_darwin-amd64 -o vendor-cfssl/out/cfssl_darwin-amd64
	curl -L https://pkg.cfssl.org/R1.2/cfssljson_darwin-amd64 -o vendor-cfssl/out/cfssljson_darwin-amd64

vendor-provision/out:
	mkdir -p vendor-provision/out/
	curl -L https://github.com/apprenda/kismatic-provision/releases/download/v1.0/provision-darwin-amd64 -o vendor-provision/out/provision-darwin-amd64
	curl -L https://github.com/apprenda/kismatic-provision/releases/download/v1.0/provision-linux-amd64 -o vendor-provision/out/provision-linux-amd64
	chmod +x vendor-provision/out/*

dist: vendor-ansible/out vendor-cfssl/out vendor-provision/out build
	mkdir -p out
	cp bin/kismatic out
	mkdir -p out/ansible
	cp -r vendor-ansible/out/* out/ansible
	rm -rf out/ansible/playbooks
	cp -r ansible out/ansible/playbooks
	mkdir -p out/ansible/playbooks/inspector
	cp -r bin/inspector/* out/ansible/playbooks/inspector
	mkdir -p out/ansible/playbooks/kuberang/linux/amd64/
	curl https://kismatic-installer.s3-accelerate.amazonaws.com/latest/kuberang -o out/ansible/playbooks/kuberang/linux/amd64/kuberang
	mkdir -p out/cfssl
	cp -r vendor-cfssl/out/* out/cfssl
	cp vendor-provision/out/provision-$(GOOS)-amd64 out/provision
	rm -f out/kismatic.tar.gz
	tar -cvzf kismatic.tar.gz -C out .
	mv kismatic.tar.gz out

integration/vendor: tools/glide
	go get github.com/onsi/ginkgo/ginkgo
	cd integration && ../tools/glide install

just-integration-test: integration/vendor
	ginkgo -p -v integration

serial-integration-test: integration/vendor
	ginkgo -v integration

docs/kismatic-cli:
	mkdir docs/kismatic-cli
	go run cmd/kismatic-docs/main.go
	cp docs/kismatic-cli/kismatic.md docs/kismatic-cli/README.md
