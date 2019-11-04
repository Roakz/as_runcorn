module QSAIdHelper
  def self.id(qsa_id, opts = {})
    link = !!opts[:link]

    out = '<span class="as-runcorn-qsa-id">'
    out << qsa_id

    if link
      parsed_id = QSAId.parse_prefixed_id(qsa_id)

      url = Rails.application.routes.url_helpers.url_for(:controller => parsed_id[:model].to_s.pluralize(2),
                                                         :action => 'show',
                                                         :id => parsed_id[:id],
                                                         :only_path => true)

      out << ' <a href="' + url + '"><span class="glyphicon glyphicon-chevron-right"></span></a>'
    end
    out << '</span>'

    out.html_safe
  end
end
