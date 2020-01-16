class FileIssueInvoice

  java_import Java::org::apache::fop::apps::FopFactory
  java_import Java::org::apache::fop::apps::Fop
  java_import Java::org::apache::fop::apps::MimeConstants
  import javax.xml.transform.stream.StreamSource
  import javax.xml.transform.TransformerFactory
  import javax.xml.transform.sax.SAXResult

  attr_reader :params

  def initialize(params)
    @params = params
  end

  AgencyLocation = Struct.new(:aspace_agency_id, :location_id, :agency_name, :location_name)

  def to_file
    @report_logo_path = File.join(File.dirname(__FILE__), '../reports/qsa-logo.png')
    @tables = build_report_tables

    renderer = ERB.new(File.read(File.join(File.dirname(__FILE__), '../reports/file_issue_invoice.fo.erb')))
    fo = renderer.result(binding).strip

    fo_stream = java.io.ByteArrayInputStream.new(fo.to_java.getBytes("UTF-8"))
    output_pdf_file = java.io.File.createTempFile("file_issue_invoice", ".pdf")
    output_stream = java.io.FileOutputStream.new(output_pdf_file)

    begin
      fopfac = FopFactory.newInstance
      fop = fopfac.newFop(MimeConstants::MIME_PDF, output_stream)
      transformer = TransformerFactory.newInstance.newTransformer()
      res = SAXResult.new(fop.getDefaultHandler)
      transformer.transform(StreamSource.new(fo_stream), res)

      output_pdf_file.path
    ensure
      output_stream.close
    end
  end

  def build_report_tables
    DB.open do |db|
      MAPDB.open do |mapdb|
        iterator = self.to_enum(:file_issue_stream, mapdb)

        # Rows of agency/location/file issue
        report_tables = {}

        agencies = {}
        location_names = {}

        while row = begin
                      iterator.next
                    rescue StopIteration
                      :end
                    end

          if (row == :end && !agencies.empty?) ||
             (row != :end && !agencies.include?(row[:aspace_agency_id]) && agencies.length == 500)

            # Pull back agency names in one hit
            agency_names = {}
            db[:name_corporate_entity]
              .filter(:agent_corporate_entity_id => agencies.keys,
                      :is_display_name => 1)
              .select(:sort_name, :agent_corporate_entity_id)
              .each do |row|
              agency_names[row[:agent_corporate_entity_id]] = row[:sort_name]
            end

            quote_ids = agencies.map {|_, locations|
              locations.values
            }.flatten.map {|row|
              row[:"aspace_#{row[:issue_type].downcase}_quote_id"]
            }

            quote_totals = {}

            db[:service_quote_line].filter(:service_quote_id => quote_ids)
              .select(Sequel.qualify(:service_quote_line, :service_quote_id),
                      Sequel.qualify(:service_quote_line, :quantity),
                      Sequel.qualify(:service_quote_line, :charge_per_unit_cents),
                      Sequel.qualify(:service_quote_line, :charge_category_id))
              .each do |quote_line|
              quote_totals[quote_line[:service_quote_id]] ||= {}
              quote_totals[quote_line[:service_quote_id]][quote_line[:charge_category_id]] ||= 0
              quote_totals[quote_line[:service_quote_id]][quote_line[:charge_category_id]] += quote_line[:quantity] * quote_line[:charge_per_unit_cents]
            end

            agencies.each do |aspace_agency_id, agency_locations|
              agency_locations.each do |location_id, rows|
                rows.each do |row|
                  quote_id = row[:"aspace_#{row[:issue_type].downcase}_quote_id"]
                  line_item_totals = quote_totals.fetch(quote_id, Hash.new("N/A"))

                  report_row = {
                    'Date' => Time.at((row[:create_time] / 1000).to_i).to_date,
                    'File Issue Request ID' => "FIR#{row[:file_issue_request_id]}",
                    'File Issue ID' => row[:issue_type] == 'PHYSICAL' ? "FIP#{row[:id]}" : "FID#{row[:id]}",
                    'Contact' => row[:lodged_by] || '',
                    '# Files' => row[:count],
                  }

                  [['Retrieval Charges', 'Retrieval'],
                   ['Delivery Charges', 'Delivery'],
                   ['Search Charges', 'Search'],
                   ['Scan Charges', 'Scan'],
                   ['Other Charges', 'Other']].each do |(label, value)|
                    enum_id = BackendEnumSource.id_for_value('runcorn_charge_category', value)
                    amount = line_item_totals[enum_id] || 0

                    report_row[label] = amount

                    if amount.is_a?(Integer)
                      report_row['Subtotal'] ||= 0
                      report_row['Subtotal'] += amount
                    end
                  end

                  # If all values were N/A, subtotal is N/A as well
                  report_row['Subtotal'] ||= 'N/A'

                  key = AgencyLocation.new(aspace_agency_id,
                                           location_id,
                                           agency_names.fetch(aspace_agency_id, ""),
                                           location_names.fetch(location_id, ""))
                  report_tables[key] ||= []
                  report_tables[key] << report_row
                end
              end
            end

            agencies.clear
            location_names.clear
          end

          if row == :end
            break
          else
            agencies[row[:aspace_agency_id]] ||= {}
            agencies[row[:aspace_agency_id]][row[:agency_location_id]] ||= []
            agencies[row[:aspace_agency_id]][row[:agency_location_id]] << row

            location_names[row[:agency_location_id]] = row[:location_name]
          end
        end

        report_tables
      end
    end
  end

  def file_issue_stream(mapdb)
    base_ds = mapdb[:file_issue]
                .join(:file_issue_request,
                      Sequel.qualify(:file_issue, :file_issue_request_id) => Sequel.qualify(:file_issue_request, :id))
                .join(:file_issue_item, Sequel.qualify(:file_issue_item, :file_issue_id) => Sequel.qualify(:file_issue, :id))
                .join(:agency_location, Sequel.qualify(:file_issue, :agency_location_id) => Sequel.qualify(:agency_location, :id))
                .join(:agency, Sequel.qualify(:file_issue, :agency_id) => Sequel.qualify(:agency, :id))
                .group_and_count(Sequel.qualify(:file_issue, :id),
                                 Sequel.as(Sequel.qualify(:agency_location, :name), :location_name),
                                 Sequel.qualify(:agency, :aspace_agency_id),
                                 Sequel.qualify(:file_issue, :agency_location_id),
                                 Sequel.qualify(:file_issue, :lodged_by),
                                 Sequel.qualify(:file_issue, :create_time),
                                 Sequel.qualify(:file_issue, :issue_type),
                                 Sequel.as(Sequel.qualify(:file_issue_request, :id), :file_issue_request_id),
                                 Sequel.qualify(:file_issue_request, :aspace_physical_quote_id),
                                 Sequel.qualify(:file_issue_request, :aspace_digital_quote_id))
                .order(Sequel.qualify(:agency, :id),
                       Sequel.qualify(:file_issue, :agency_location_id),
                       Sequel.qualify(:file_issue, :create_time))

    if params['agency_uri']
      parsed_aspace_agency = JSONModel.parse_reference(params['agency_uri'])
      aspace_agency_id = parsed_aspace_agency.fetch(:id)

      base_ds = base_ds
                  .filter(Sequel.qualify(:file_issue, :agency_id) =>
                          mapdb[:agency]
                            .filter(:aspace_agency_id => aspace_agency_id)
                            .select(:id))
    end

    # FIXME location & dates too

    result = ""

    base_ds.extension(:pagination).each_page(500) do |page_ds|
      page_ds.each do |row|
        yield row
      end
    end

    result
  end

end
