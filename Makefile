PROMPT=$$$$$$S
ifeq ($(OS),Windows_NT)
    SHELL=CMD.EXE
    NUL=NUL
    DEL=del
    DELTREE=rmdir /s
    SET=set
    TYPE=type
    GITDIR=$(or $(GIT_INSTALL_ROOT),$(shell for %%I in (git.exe) do echo %%~dp$$PATH:I..))
    AWK="$(GITDIR)\usr\bin\gawk.exe"
    D=$\\
else
    NUL=/dev/null
    SET=export
    DEL=rm
    DELTREE=rm -r
    TYPE=cat
    AWK=gawk
    D=/
endif

snapshot: fmt nyagos.syso
	$(SET) "CGO_ENABLED=0" && go build -ldflags "-s -w -X main.version=$(shell git.exe describe --tags)"

debug:
	$(SET) "CGO_ENABLED=0" && go build -ldflags "-s -w -X main.version=$(shell git.exe describe --tags)" -tags=debug

test: tstlua
	cd alias    && go test
	cd commands && go test
	cd history  && go test
	cd mains    && go test
	cd nodos    && go test
	cd shell    && go test
	cd texts    && go test

tstlua:
	$(foreach I,$(wildcard luatst/*.lua),echo $(I) && nyagos --norc -f "$(I)" && ) :

release: fmt nyagos.syso
	cd bin          2>$(NUL) || mkdir bin
	cd bin$(D)386   2>$(NUL) || mkdir bin$(D)386
	cd bin$(D)amd64 2>$(NUL) || mkdir bin$(D)amd64
	$(SET) "GOOS=windows"  && $(SET) "GOARCH=386"   && go build -o bin/386/nyagos.exe   -ldflags "-s -w"
	$(SET) "GOOS=windows"  && $(SET) "GOARCH=amd64" && go build -o bin/amd64/nyagos.exe -ldflags "-s -w"
	$(SET) "CGO_ENABLED=0" && $(SET) "GOOS=linux"   && $(SET) "GOARCH=amd64" && go build -ldflags "-s -w"

clean:
	-$(DELTREE) bin 2>$(NUL)
	-$(DEL) nyagos.exe nyagos nyagos.syso 2>$(NUL)

fmt:
	git status -s | $(AWK) "/^.M.*\.go/{ system(\"go fmt \" $$NF) }"

nyagos.syso:
	cd Etc && go generate

get:
	go get -u
	go get -u github.com/nyaosorg/go-readline-ny@master
	go mod tidy

VERSION=$(shell $(TYPE) Etc$(D)version.txt)

_zip:
	zip -9j "nyagos-$(VERSION)-windows-$(GOARCH).zip" \
	    "bin$(D)$(GOARCH)$(D)nyagos.exe" .nyagos _nyagos makeicon.cmd LICENSE \
	    "Etc$(D)*.ico"
	zip -9  "nyagos-$(VERSION)-windows-$(GOARCH).zip" \
	    "nyagos.d$(D)*.lua" "nyagos.d$(D)catalog$(D)*.lua"

package:
	make _zip GOARCH=386
	make _zip GOARCH=amd64
	tar zcvf "nyagos-$(VERSION)-linux-amd64.tar.gz" -C .. \
	    nyagos/nyagos nyagos/.nyagos nyagos/_nyagos nyagos/nyagos.d

workspace:
	cd .. && go work init go-readline-ny nyagos

unworkspace:
	$(DEL) ..$(D)go.work
	$(MAKE) get

ifeq ($(OS),Windows_NT)
install:
ifeq ($(INSTALLDIR),)
	@echo Please do $(MAKE) INSTALLDIR=...
	@echo or set INSTALLDIR=...
else
	copy /-Y  _nyagos    "$(INSTALLDIR)$(D)."
	xcopy "nyagos.d$(D)*"  "$(INSTALLDIR)$(D)nyagos.d" /E /I /Y
	copy /-Y  nyagos.exe "$(INSTALLDIR)$(D)." || ( \
	move "$(INSTALLDIR)$(D)nyagos.exe" "$(INSTALLDIR)$(D)nyagos.exe-%RANDOM%" && \
	copy nyagos.exe  "$(INSTALLDIR)$(D)." )
endif

update:
	for /F "skip=1" %%I in ('where nyagos.exe') do $(MAKE) install INSTALLDIR=%%~dpI
endif