require "open3"
require "rainbow"

namespace :efolder do
  desc "shortcut to run all linting tools, at the same time."
  task :security do
    puts "Running all security linting tools"
    puts "running Brakeman security scan..."
    brakeman_result = ShellCommand.run(
      "brakeman --exit-on-warn --run-all-checks --confidence-level=2"
    )

    puts "running bundle-audit to check for insecure dependencies..."
    exit!(1) unless ShellCommand.run("bundle-audit update")

    snoozed_cves = [
      # Example:
      # { cve_name: "CVE-2018-1000201", until: Time.utc(2018, 9, 10) }
      { cve_name: "CVE-2015-9284", until: Time.utc(2019, 12, 31) }
    ]

    alerting_cves = snoozed_cves
      .select { |cve| cve[:until] >= Time.now.utc }
      .map { |cve| cve[:cve_name] }

    audit_cmd = "bundle-audit check --ignore=#{alerting_cves.join(' ')}"

    puts audit_cmd

    audit_result = ShellCommand.run(audit_cmd)

    puts "\n"
    if brakeman_result && audit_result
      puts Rainbow("Passed. No obvious security vulnerabilities.").green
    else
      puts Rainbow("Failed. Security vulnerabilities were found.").red
      exit!(1)
    end
  end
end
