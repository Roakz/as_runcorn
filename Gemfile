ASpaceGems.setup if defined? ASpaceGems

gem "aws-sdk-s3"

if ENV['RELEASE_BRANCH']
  branch = ENV['RELEASE_BRANCH']
  $stderr.puts("Building with xlsx_streaming_reader=#{branch}")

  gem "xlsx_streaming_reader", git: "https://github.com/hudmol/xlsx_streaming_reader.git", branch: branch
else
  xlsx_streaming_reader_ref = nil

  gemfile_lock = Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile))
  gemfile_lock.sources.each do |src|
    next unless src.is_a?(Bundler::Source::Git)

    if src.name == 'xlsx_streaming_reader'
      xlsx_streaming_reader_ref = src.ref
    end
  end

  # If we're running without an explicit branch set, just figure out what
  # version is meant to be loaded by looking at Gemfile.lock.
  if xlsx_streaming_reader_ref
    $stderr.puts("xlsx_streaming_reader=#{xlsx_streaming_reader_ref}")
    gem "xlsx_streaming_reader", git: "https://github.com/hudmol/xlsx_streaming_reader.git", branch: xlsx_streaming_reader_ref
  else
    raise "Please set the RELEASE_BRANCH environment variable to `qa` or `master` " +
          "to select which versions of xlsx_streaming_reader to build with"
  end
end
