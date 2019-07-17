desc "Runs the continuous integration scripts"
task ci: ["efolder:lint", "security", "efolder:bundle_javascript", "spec"]

task default: :ci
