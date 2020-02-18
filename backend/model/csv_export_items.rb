class CsvExportItems < CsvExport

  def columns
    [
      Column.new('Record Type', proc{|record| record.type}),
      Column.new('Item ID', proc{|record| record.id}),
      Column.new('Item Name', proc{|record| record.title}),
      Column.new('Start Date', proc{|record| record.start_date}),
      Column.new('Certainty', proc{|record| record.start_date_certainty}),
      Column.new('End Date', proc{|record| record.end_date}),
      Column.new('Certainty', proc{|record| record.end_date_certainty}),
      Column.new('No of Child Items', proc{|record| record.number_of_children}),
      Column.new('No of Physical Representations', proc{|record| record.number_of_physical_representations}),
      Column.new('No of Digital Representations', proc{|record| record.number_of_digital_representations}),
      Column.new('Parent Item ID', proc{|record| record.parent_item_id}),
      Column.new('Series ID', proc{|record| record.series_id}),
      Column.new('Series Name', proc{|record| record.series_name}),
      Column.new('Responsible Agency ID', proc{|record| record.responsible_agency_id}),
      Column.new('Responsible Agency Name', proc{|record| record.responsible_agency_name}),
      Column.new('RAP Duration', proc{|record| record.rap_years}),
      Column.new('RAP Expiry Date', proc{|record| record.rap_expiry_date}),
      Column.new('Access Category', proc{|record| record.access_category}),
      Column.new('RAP Publish Details?', proc{|record| record.rap_publish_details}),
      Column.new('RAP Inherited?', proc{|record| record.rap_inherited}),
      Column.new('No of Representations with Overriding RAPs', proc{|record| record.number_of_representations_with_overriding_raps}),
      Column.new('Significance', proc{|record| record.significance}),
      Column.new('Inherit Significance?', proc{|record| record.inherit_significance}),
      Column.new('No of Representations with overriding Significance', proc{|record| record.number_of_representations_with_overriding_significance}),
      Column.new('Sensitivity Label', proc{|record| record.sensitivity_label}),
      Column.new('Archivist Approved?', proc{|record| record.archivist_approved}),
      Column.new('Approval Date', proc{|record| record.archivist_approval_date}),
      Column.new('Approved By', proc{|record| record.archivist_approved_by}),
      Column.new('Published?', proc{|record| record.published}),
      Column.new('Restrictions Apply?', proc{|record| record.restrictions_apply}),
      Column.new('Agency Control No.', proc{|record| record.agency_control_number}),
      Column.new('Previous System Location', proc{|record| record.previous_system_identifier}),
      Column.new('Accession Status', proc{|record| record.accessioned_retention_status}),
      Column.new('Disposal Class', proc{|record| record.disposal_class}),
      Column.new('Copyright Status', proc{|record| record.copyright_status}),
      Column.new('Transfer ID', proc{|record| record.transfer_id}),
      Column.new('Transfer Name', proc{|record| record.transfer_name}),
      Column.new('Original Registration Date', proc{|record| record.original_registration_date}),
      Column.new('Created Date', proc{|record| record.created_date}),
      Column.new('Created By', proc{|record| record.created_by}),
      Column.new('Last Modified Date', proc{|record| record.last_modified_date}),
      Column.new('Last Modified By', proc{|record| record.last_modified_by}),
    ]
  end

  def process_results(solr_response, csv)
    resolver = SearchResolver.new(['ancestors:id'])
    resolver.resolve(solr_response)
    super
  end

  def record_for_solr_doc(doc)
    record = super
    if Array(doc['ancestors']).length > 0
      parent = Array(doc['_resolved_ancestors'].fetch(doc['ancestors'].first, nil)).first
      series = Array(doc['_resolved_ancestors'].fetch(doc['ancestors'].last, nil)).first

      parent_item_id = nil
      series_id = nil
      series_name = nil

      if parent && parent['primary_type'] == 'archival_object'
        parent_item_id = parent['qsa_id_u_ssort']
      end

      if series
        series_id = series['qsa_id_u_ssort']
        series_name = series['title']
      end

      record.append_extra_data({
                                :parent_item_id => parent_item_id,
                                :series_id => series_id,
                                :series_name => series_name,
                               })
    end

    record
  end

end