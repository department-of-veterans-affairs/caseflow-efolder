desc "Runs the continuous integration scripts"
task ci: ["efolder:lint", "efolder:security", "spec"]

task default: :ci
