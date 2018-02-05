desc "Runs the continuous integration scripts"
task ci: ["efolder:lint", "efolder:security", "spec", "efolder:sauceci"]

task default: :ci
