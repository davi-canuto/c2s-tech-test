module ParserRecordsHelper
  def status_badge(status)
    badge_class = case status
                  when 'success' then 'bg-success'
                  when 'failed' then 'bg-danger'
                  when 'processing' then 'bg-warning'
                  else 'bg-secondary'
                  end

    content_tag(:span, t("common.statuses.#{status}"), class: "badge #{badge_class}")
  end

  def status_options
    [
      [t('common.labels.all_statuses'), ''],
      [t('common.statuses.pending'), 'pending'],
      [t('common.statuses.processing'), 'processing'],
      [t('common.statuses.success'), 'success'],
      [t('common.statuses.failed'), 'failed']
    ]
  end
end
