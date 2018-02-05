desc "Runs the continuous integration scripts"
task ci: ["efolder:lint", "efolder:security", "efolder:spec", "efolder:sauceci"]

task default: :ci
