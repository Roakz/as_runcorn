module QSAIdHelper
  def self.id(qsa_id, opts = {})
    parsed_id = QSAId.parse_prefixed_id(qsa_id)
    return unless parsed_id[:model]

    out = '<span class="as-runcorn-qsa-id">'
    out << qsa_id

    # the :link option can be either an id for, or a uri to, the record
    # or, if it's just true, then it'll send it off to the resolver to work it out for itself
    if opts.has_key?(:link)
      if opts[:link] == true
        url_hash = {
          :controller => 'qsa_id',
          :action => 'show',
          :qsa_id => qsa_id,
          :only_path => true
        }
      else
        link_id = opts[:link].to_s.split('/').last
        url_hash = {
          :controller => parsed_id[:model].to_s.pluralize(2),
          :action => 'show',
          :id => link_id,
          :only_path => true
        }

        if parsed_id[:model].to_s.start_with?('agent')
          url_hash[:controller] = 'agents'
          url_hash[:agent_type] = parsed_id[:model].to_s
        end
      end

      url = Rails.application.routes.url_helpers.url_for(url_hash)

      out << ' <a href="' + url + '"><span class="glyphicon glyphicon-chevron-right"></span></a>'
    end
    out << '</span>'

    out.html_safe
  end
end
