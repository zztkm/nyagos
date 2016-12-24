package dos

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"

	"github.com/zetamatta/go-findfile"
)

func lookPath(dir1, pattern string) (foundpath string) {
	pathExtList := filepath.SplitList(os.Getenv("PATHEXT"))
	findfile.Walk(pattern, func(f *findfile.FileInfo) bool {
		if f.IsDir() {
			return true
		}
		suffix_ := filepath.Ext(f.Name())
		for _, suffix1 := range pathExtList {
			if strings.EqualFold(suffix_, suffix1) {
				foundpath = filepath.Join(dir1, f.Name())
				if !f.IsReparsePoint() {
					return false
				}
				var err error
				foundpath, err = os.Readlink(foundpath)
				if err == nil {
					if filepath.IsAbs(foundpath) {
						return false
					}
					foundpath = filepath.Join(dir1, foundpath)
					return false
				} else if dbg {
					print(err.Error(), "\n")
				}
			}
		}
		return true
	})
	return
}

func LookPath(name string, envnames ...string) string {
	if strings.ContainsAny(name, "\\/:") {
		return lookPath(filepath.Dir(name), name+".*")
	}
	var envlist bytes.Buffer
	envlist.WriteString(".;")
	envlist.WriteString(os.Getenv("PATH"))
	for _, name1 := range envnames {
		envlist.WriteString(";")
		envlist.WriteString(os.Getenv(name1))
	}
	// println(envlist.String())
	pathDirList := filepath.SplitList(envlist.String())

	for _, dir1 := range pathDirList {
		// println("lookPath:" + dir1)
		if path := lookPath(dir1, filepath.Join(dir1, name+".*")); path != "" {
			// println("Found:" + path)
			return path
		}
	}
	return ""
}