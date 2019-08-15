module RAPsApplied

  def self.included(base)
    base.extend(ClassMethods)
  end

  class RAPApplications

    def initialize(objs)
      @rap_applied_by_representation_id = {}
      @active_raps_by_id = {}
      @expiry_date_by_representation_id = {}
      @existence_end_date_by_representation_id = {}

      load!(objs)
    end

    def rap_json_for_representation(representation_id)
      active_rap = @rap_applied_by_representation_id.fetch(representation_id, []).find {|rap_applied| rap_applied[:is_active] == 1}

      raise "ASSERTION FAILED: No active rap for #{representation_id}" unless active_rap

      active_rap['expiry_date']

      @active_raps_by_id.fetch(active_rap[:rap_id])
    end

    def rap_history_for_representation(representation_id)
      @rap_applied_by_representation_id.fetch(representation_id, [])
        .sort_by {|rap_applied| rap_applied[:id]}
        .map {|rap_applied|
        {
          'ref' => JSONModel::JSONModel(:rap).uri_for(rap_applied[:rap_id], { :repo_id => RequestContext.get(:repo_id) }),
          'is_active' => rap_applied[:is_active] == 1,
        }
      }
    end

    def rap_expiration_for_representation(representation_id)
      expiry_date = @expiry_date_by_representation_id.fetch(representation_id, nil)

      if expiry_date.nil?
        return {
          'expired' => false,
          'expires' => false,
        }
      end

      {
        'existence_end_date' => @existence_end_date_by_representation_id.fetch(representation_id, nil)&.iso8601,
        'expiry_date' => expiry_date.iso8601,
        'expired' => expiry_date < Date.today,
        'expires' => true,
      }
    end

    private

    def load!(representation_objs)
      backlink_col = :"#{representation_objs[0].class.table_name}_id"

      DB.open do |db|
        db[:rap_applied].filter(backlink_col => representation_objs.map(&:id)).each do |row|
          @rap_applied_by_representation_id[row[backlink_col]] ||= []
          @rap_applied_by_representation_id[row[backlink_col]] << row
        end

        active_rap_ids = @rap_applied_by_representation_id.values
                           .flatten
                           .select {|row| row[:is_active] == 1}
                           .map {|row| row[:rap_id]}
                           .uniq

        RAP.sequel_to_jsonmodel(RAP.filter(:id => active_rap_ids).all).each do |rap|
          @active_raps_by_id[rap.id] = rap
        end

        date_existence_enum_id = db[:enumeration_value]
                                  .join(:enumeration, Sequel.qualify(:enumeration, :id) => Sequel.qualify(:enumeration_value, :enumeration_id))
                                  .filter(Sequel.qualify(:enumeration_value, :value) => 'existence')
                                  .filter(Sequel.qualify(:enumeration, :name) => 'date_label')
                                  .select(Sequel.qualify(:enumeration_value, :id))


        containing_ao_ids = representation_objs.collect{|obj| obj[:archival_object_id]}
        ao_id_to_end_date = {}

        db[:date]
          .filter(:archival_object_id => containing_ao_ids)
          .filter(:label_id => date_existence_enum_id)
          .order(:archival_object_id, :id)
          .select(:archival_object_id,
                  :end)
          .each do |row|
          ao_id_to_end_date[row[:archival_object_id]] ||= handle_fuzzy_date(row[:end])
        end

        representation_objs.each do |representation_obj|
          @existence_end_date_by_representation_id[representation_obj.id] = ao_id_to_end_date.fetch(representation_obj[:archival_object_id], nil)
          @expiry_date_by_representation_id[representation_obj.id] = calculate_expiry_date_for(representation_obj, ao_id_to_end_date.fetch(representation_obj[:archival_object_id], Date.today))
        end
      end
    end

    def calculate_expiry_date_for(representation_obj, end_date)
      rap_applied_row = @rap_applied_by_representation_id.fetch(representation_obj.id).find{|row| row[:is_active] == 1}
      rap = @active_raps_by_id.fetch(rap_applied_row[:rap_id])

      return nil if rap.years.nil?

      rap_expiry_date = end_date.next_year(rap.years)

      if rap.access_category == 'Cabinet matters'
        rap_expiry_date = Date.new(rap_expiry_date.year + 1, 1, 1)
      end

      rap_expiry_date
    end

    def handle_fuzzy_date(s)
      return Date.today if s.nil?

      default = [Date.today.year.to_s, '12', '31']
      bits = s.split('-')

      full_date = (0...3).map {|i| bits.fetch(i, default.fetch(i))}.join('-')

      begin
        Date.parse(full_date)
      rescue
        Date.today
      end
    end
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      begin
        jsons = super

        return jsons if objs.empty?

        raps = RAPApplications.new(objs)

        objs.zip(jsons).each do |obj, json|
          json['rap_applied'] = raps.rap_json_for_representation(obj.id)
          json['rap_history'] = raps.rap_history_for_representation(obj.id)
          json['rap_expiration'] = raps.rap_expiration_for_representation(obj.id)
        end

        jsons
      rescue
        $stderr.puts($!)
        $stderr.puts($@.join("\n"))
      end
    end

    def handle_delete(ids_to_delete)
      backlink_col = :"#{self.table_name}_id"

      DB.open do |db|
        db[:rap_applied].filter(backlink_col => ids_to_delete).delete
      end

      super
    end
  end

end
