module SignificanceHelper
  SIG_LABEL_MAP = {
    'standard' => 'default',
    'high' => 'info',
    'iconic' => 'warning',
    'memory_of_the_world' => 'danger',
  }

  def self.display(sig, count = false)
    out = '<span class="label label-' + SignificanceHelper::SIG_LABEL_MAP[sig] + '" style="font-size:small;margin-right:10px;">'
    out += I18n.t("enumerations.runcorn_significance.#{sig}")
    out += ': ' + count.to_s if count
    out << '</span>'
    out.html_safe
  end
end
