desc "Runs the continuous integration scripts"
task ci: [:lint, :security, :spec, :sauceci]

task default: :ci
