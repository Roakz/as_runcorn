module AllExistenceDates

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        dates = DateCalculator.new(obj, 'existence', true, :allow_open_end => true)
        json['all_existence_dates_range'] = [dates.min_begin, dates.max_end].join(' -- ')

        json['dates'].select{|d| d['label'] == 'existence'}.map do |d|
          d['begin'] = dates.min_begin
          d['end'] = dates.max_end if d['end']
        end
      end

      jsons
    end
  end
end
