module AllExistenceDates

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        dates = DateCalculator.new(obj, 'existence')
        json['all_existence_dates_range'] = [dates.min_begin, dates.max_end].join(' -- ')
      end

      jsons
    end
  end
end
