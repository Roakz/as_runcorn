ASpaceGems.setup if defined? ASpaceGems

# If you change these, you may want to rm -rf ./local_gems/ and rerun
# bootstrap.sh to pull down your updated versions.
local_gems = [
  {
    gem: "xlsx_streaming_reader",
    url: "https://github.com/hudmol/xlsx_streaming_reader.git",
    ref: "tags/qa",
  },
]


local_gems_path = File.join(File.dirname(__FILE__), "local_gems")

FileUtils.mkdir_p(local_gems_path)

local_gems.each do |gem|
  checkout_dir = File.join(local_gems_path, gem.fetch(:gem))

  # If the gem hasn't been checked out to local_gems/, grab a copy now.
  unless Dir.exist?(checkout_dir)
    system("git", "clone", gem.fetch(:url), checkout_dir)
    system("git", "-C", checkout_dir, "reset", "--hard", gem.fetch(:ref))
  end

  # Add to load path
  $LOAD_PATH << File.join(checkout_dir, 'lib')
end

# Require dependencies
local_gems.each do |gem|
  require gem.fetch(:gem)
end


gem "aws-sdk-s3"
