namespace :efolder do
  desc "package javascript source files into bundle"
  task :bundle_javascript do
    exit!(1) unless ShellCommand.run("cd client && yarn run build")
  end
end
