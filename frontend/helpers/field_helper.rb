module FieldHelper
  def self.reorder_fields(hash, field_order)
    fields = {}
    field_order.each do |field_name|
      if hash.has_key?(field_name)
        fields[field_name] = hash[field_name]
        hash.delete(field_name)
      end
    end
    fields.each_pair { |key, field| hash[key] = field }

    hash
  end
end
