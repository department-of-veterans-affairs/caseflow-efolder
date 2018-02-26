desc "Runs the continuous integration scripts"
task ci: ["efolder:lint", "efolder:security", "efolder:bundle_javascript", "spec"]

task default: :ci
