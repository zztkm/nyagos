PROMPT=$$$$$$S

snapshot:
	$(MAKE) fmt
	for /F %%V in ('git.exe describe --tags') do \
	    go build -ldflags "-s -w -X main.version=%%V"

release:
	$(MAKE) fmt
	if not exist bin mkdir bin
	for %%I in (386 amd64) do \
	    if not exist bin\%%I mkdir bin\%%I
	for %%D in (%CD%) do \
	for %%I in (386 amd64) do \
	    set "GOARCH=%%I" & go build -o bin/%%I/%%~nD.exe -ldflags "-s -w"
	( set "GOOS=linux" & go build -ldflags "-s -w" )

clean:
	if exist bin rmdir /s bin

# Without ( and ) , set is called as an external command in nmake

fmt:
	- for /F %%I in ('dir /b /s /AA *.go') do \
	    go fmt "%%I" & attrib -A "%%I"

syso:
	pushd $(MAKEDIR)\Etc & go generate & popd

get:
	go get -u
#	go get -u github.com/zetamatta/go-readline-ny@master
	go mod tidy

package:
	for /F %%V in ('type Etc\version.txt') do \
	for %%D in (%CD%) do \
	for %%A in (386 amd64) do \
	for %%N in (%%~nD-%%V-windows-%%A.zip) do \
	    zip -9j "%%N" "bin\%%A\nyagos.exe" .nyagos _nyagos makeicon.cmd LICENSE & \
	    zip -9  "%%N" nyagos.d\*.lua nyagos.d\catalog\*.lua
	for /F %%V in ('type Etc\version.txt') do \
	for %%D in (%CD%) do \
	for %%A in (amd64) do \
	    tar -zcvf "nyagos-%%V-linux-%%A.tar.gz" -C .. \
		%%~nD/nyagos \
		%%~nD/.nyagos \
		%%~nD/_nyagos \
		%%~nD/nyagos.d

_install:
	for /F "skip=1" %%I in ('where nyagos.exe') do \
	    copy /-Y nyagos.exe "%%I"

install:
	start "" "$(MAKE)" _install

batch:
	makefile2batch > make.bat