// Package gitrepostatus provides details for the Git Repo Status applet.
package gitrepostatus

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed git_repo_status.star
var source []byte

// New creates a new instance of the Git Repo Status applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "git-repo-status",
		Name:        "Git Repo Status",
		Author:      "joevgreathead",
		Summary:     "Activity for Github repos",
		Desc:        "Displays activity and current state of open PRs and Issues on your (public) Github repo of choice.",
		FileName:    "git_repo_status.star",
		PackageName: "gitrepostatus",
		Source:  source,
	}
}
