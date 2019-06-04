MAPDB = Class.new do

  def [](*args)
    DummySequelDataset.new
  end

  def method_missing(*args)
    self
  end

  def self.connect
    self.new
  end

  def self.open
    yield self.new
  end

  class DummySequelDataset
    def [](*args)
      nil
    end

    def each(*args)
      []
    end

    def method_missing(*args)
      self
    end
  end

  def self.to_s
    "DUMMY_MAPDB_FOR_TESTING"
  end
end
