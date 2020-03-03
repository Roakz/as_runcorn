class ImpliedPublicationCalculator

  def initialize
  end

  def for_subjects(objs)
    DummyPublicationObj.new
  end

  class DummyPublicationObj
    def fetch(obj)
      true
    end
  end

end
