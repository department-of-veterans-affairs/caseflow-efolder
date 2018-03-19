# This is called during the deploy script to link files relied on by uswds styles.
#
# Mirror what react-on-rails does for caseflow since we do not use react-on-rails for efolder.
# https://github.com/shakacode/react_on_rails/blob/8c8077b3b86680581aef5f49908225aa33ea25fd/lib/react_on_rails/assets_precompile.rb#L59
desc "symlink assets for reference by filename without digest"
task :symlink_assets do
  assets_path = File.join(Rails.root, "public/assets/")
  manifest_glob = Dir.glob("#{assets_path}.sprockets-manifest-*.json") +
                  Dir.glob("#{assets_path}manifest-*.json") +
                  Dir.glob("#{assets_path}manifest.yml")

  if manifest_glob.empty?
    puts "Warning: React On Rails: expected to find .sprockets-manifest-*.json, manifest-*.json "\
             "or manifest.yml at #{assets_path}, but found none. Canceling symlinking tasks."
    return -1
  end

  manifest_path = manifest_glob.first
  manifest_file = File.new(manifest_path)
  manifest_data = if File.extname(manifest_file) == ".json"
                    manifest_file_data = File.read(manifest_path)
                    JSON.parse(manifest_file_data)["assets"]
                  else
                    YAML.safe_load(manifest_file)
                  end

  manifest_data.each do |asset_name, file_name|
    # Only symlink .woff font files.
    next unless asset_name =~ /\.woff2?$/
    puts "linking #{asset_name}"

    file_path = File.join(Rails.root, "public/assets", file_name)
    asset_path = File.join(Rails.root, "public/assets", asset_name)
    FileUtils.ln_s(file_path, asset_path, force: true)
  end
end
