package deptool

import (
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

const ( // Supported dependencies
	DependencyLibluau = "libluau"
	DependencyLibpng  = "libpng"
	DependencyLibjolt = "libjolt"

	// Supported platforms
	PlatformAll     = "all"
	PlatformSource  = "source"
	PlatformAndroid = "android"
	PlatformIOS     = "ios"
	PlatformMacos   = "macos"
	PlatformWindows = "windows"
	PlatformLinux   = "linux"
)

var (
	supportedDependencies = []string{DependencyLibluau, DependencyLibpng, DependencyLibjolt}
	supportedPlatforms    = []string{PlatformSource, PlatformAndroid, PlatformIOS, PlatformMacos, PlatformWindows, PlatformLinux}
)

func isDependencyNameValid(name string) bool {
	return slices.Contains(supportedDependencies, name)
}

func isPlatformNameValid(name string) bool {
	return slices.Contains(supportedPlatforms, name) || name == PlatformAll
}

func constructDepArtifactsPath(depName, version, platform string) string {
	return filepath.Join(depName, version, "prebuilt", platform)
}

// Check if a dependency is installed
//
// Return values:
// - string: the full path to the dependency files
// - bool: whether the dependency is installed
// - error
func areDependencyFilesInstalled(depsDirPath, depName, version, platform string) (string, bool, error) {
	// fullDepPath is like: [...]/cubzh/deps/libpng/1.6.47/prebuilt/macos
	fullDepPath := filepath.Join(depsDirPath, constructDepArtifactsPath(depName, version, platform))

	// check if the directory exists
	_, err := os.Stat(fullDepPath)
	if err != nil {
		if os.IsNotExist(err) {
			// directory does not exist
			return fullDepPath, false, nil
		}
		// error
		return "", false, fmt.Errorf("failed to check if directory exists: %w", err)
	}

	// directory exists (but it can be empty)

	headerFileCount := 0
	sourceFileCount := 0
	libFileCount := 0

	// walk the directory recursively and check if there are any files
	err = filepath.Walk(fullDepPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() { // found a file
			if strings.HasSuffix(path, ".h") || strings.HasSuffix(path, ".hpp") {
				headerFileCount++
			} else if strings.HasSuffix(path, ".c") || strings.HasSuffix(path, ".cpp") {
				sourceFileCount++
			} else if strings.HasSuffix(path, ".a") || strings.HasSuffix(path, ".lib") {
				libFileCount++
			}
		}

		return nil
	})
	if err != nil {
		return "", false, fmt.Errorf("failed to walk directory: %w", err)
	}

	// if no headers or (no libs and no sources) found,
	// it means the dependency is not installed
	if headerFileCount == 0 || (libFileCount == 0 && sourceFileCount == 0) {
		return fullDepPath, false, nil
	}

	return fullDepPath, true, nil
}
