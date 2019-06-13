module RuncornDeaccession

  def update_from_json(json, opts = {}, apply_nested_records = true)
    is_being_deaccessioned = false

    if json['deaccessions'].length > 0 && !self.deaccessioned?
      is_being_deaccessioned = true
    end

    result = super

    if is_being_deaccessioned
      self.deaccession!
    end

    result
  end

end