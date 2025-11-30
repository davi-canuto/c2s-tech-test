class DashboardPresenter
  def stats
    @stats ||= {
      customers: Customer.count,
      total: ParserRecord.count,
      successful: ParserRecord.successful.count,
      failed: ParserRecord.failed_records.count
    }
  end

  def recent_customers(limit: 5)
    @recent_customers ||= Customer.recent.limit(limit)
  end

  def recent_records(limit: 5)
    @recent_records ||= ParserRecord.recent.limit(limit)
  end

  def total_customers
    stats[:customers]
  end

  def total_records
    stats[:total]
  end

  def successful_records
    stats[:successful]
  end

  def failed_records
    stats[:failed]
  end
end
