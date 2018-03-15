desc "Runs the continuous integration scripts"
task ci: ["efolder:lint", "efolder:security", "efolder:bundle_javascript", "efolder:symlink_assets", "spec"]

task default: :ci
