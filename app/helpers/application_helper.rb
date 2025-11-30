module ApplicationHelper
  def flash_class(type)
    {
      notice: "success",
      success: "success",
      alert: "danger",
      error: "danger",
      warning: "warning",
      info: "info"
    }.fetch(type.to_sym, "info")
  end
end
