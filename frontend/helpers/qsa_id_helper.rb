module QSAIdHelper
  def self.id(qsa_id)
    out = '<span class="as-runcorn-qsa-id">'
    out << qsa_id
    out << '</span>'
    out.html_safe
  end
end
