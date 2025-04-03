package deptool

import (
	"os"
	"path/filepath"
	"slices"
)

const ( // Supported dependencies
	DependencyLibluau = "libluau"
	DependencyLibpng  = "libpng"

	// Supported platforms
	PlatformAll     = "all"
	PlatformSource  = "source"
	PlatformAndroid = "android"
	PlatformIOS     = "ios"
	PlatformMacos   = "macos"
	PlatformWindows = "windows"
	PlatformLinux   = "linux"

	// PlatformWeb     = "web"
)

var (
	supportedDependencies = []string{DependencyLibluau, DependencyLibpng}
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

// TODO: make the testing more robust
func areDependencyFilesInstalled(depsDirPath, depName, version, platform string) (string, bool) {
	// check if the dependency files exist
	fullDepPath := filepath.Join(depsDirPath, constructDepArtifactsPath(depName, version, platform))
	_, err := os.Stat(fullDepPath)
	exists := err == nil
	return fullDepPath, exists
}
