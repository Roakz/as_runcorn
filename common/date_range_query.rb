DateRangeQuery = Struct.new(:date_field) do
  def to_solr_s(query)
    start_date, end_date = [query['from'] || '0000-01-01', query['to'] || '9999-12-31'].sort

    "(%s:[%s TO %s])" % [
      self.date_field,
      self.class.date_pad_start(start_date),
      self.class.date_pad_end(end_date),
    ]
  end

  def self.date_pad_start(s)
    default = ['0000', '01', '01']
    bits = s.to_s.split('-')

    (0...3).map {|i| bits.fetch(i, default.fetch(i))}.join('-')
  end


  def self.date_pad_end(s)
    default = ['9999', '12', '31']
    bits = s.to_s.split('-')

    (0...3).map {|i| bits.fetch(i, default.fetch(i))}.join('-')
  end
end
