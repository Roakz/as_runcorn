class RepresentationFileStore

  # Note: This is in bytes.  Once hex-encoded the string will be double in length.
  KEY_LENGTH = 16

  class FileNotFound < StandardError
  end

  def store_file(upload_file)
    key = generate_key
    target_file = File.join(base_dir, path_for_key(key))

    FileUtils.mkdir_p(File.dirname(target_file))

    FileUtils.cp(upload_file.tempfile.path,
                 target_file)

    key
  end

  def get_file(key)
    target_file = File.join(base_dir, path_for_key(key))

    if File.exist?(target_file)
      target_file
    else
      raise FileNotFound.new(key)
    end
  end


  private

  def base_dir
    File.join(AppConfig[:shared_storage], "representations")
  end

  def generate_key
    SecureRandom.hex(KEY_LENGTH)
  end

  def path_for_key(key)
    key = key.to_s
    raise "Key is not well-formed: #{key}" unless key =~ /\A[0-9a-f]{#{KEY_LENGTH * 2}}\z/

    File.join(key[0...2], key[2...4], key)
  end

end
