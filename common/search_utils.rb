class SearchUtils
  def self.pad_top_container_identifier(string)
    return nil if string.nil?

    # S10821-T110-B1.00
    string.scan(/([0-9]+|[^0-9]+)/).flatten.map{|bit|
      if bit =~ /\A[0-9]+\Z/
        bit.rjust(12, '0')
      else
        bit
      end
    }.join
  end

  def self.rewrite_top_container_identifier_queries(advanced_query)
    if advanced_query.is_a?(JSONModelType)
      return JSONModel::JSONModel(:advanced_query).from_hash(rewrite_top_container_identifier_queries(advanced_query.to_hash(:trusted)))
    elsif advanced_query.is_a?(Hash)
      if advanced_query['jsonmodel_type'] == 'range_query'
        if advanced_query['field'] == 'top_container_identifier'
          advanced_query['from'] = pad_top_container_identifier(advanced_query['from'])
          advanced_query['to'] = pad_top_container_identifier(advanced_query['to'])
        end
      else
        advanced_query.values.each do |v|
          rewrite_top_container_identifier_queries(v)
        end
      end
    elsif advanced_query.is_a?(Array)
      advanced_query.each do |v|
        rewrite_top_container_identifier_queries(v)
      end
    end

    advanced_query
  end

end