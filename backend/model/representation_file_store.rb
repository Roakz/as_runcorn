class RepresentationFileStore

  def store_file(upload_file)
    ByteStorage.get.store(upload_file.tempfile)
  end

  def get_file(key, &block)
    begin
      ByteStorage.get.get_stream(key, &block)
    rescue => e
      Log.error("Failure while fetching digital representation with key #{key}")
      Log.exception(e)
      raise e
    end
  end

end
