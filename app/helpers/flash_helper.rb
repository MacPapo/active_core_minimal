module FlashHelper
  FLASH_CLASSES = {
    notice: "alert-success text-white",
    success: "alert-success text-white",
    alert: "alert-error text-white",
    error: "alert-error text-white",
    warning: "alert-warning text-black",
    info: "alert-info text-white"
  }.freeze

  def flash_class(type)
    FLASH_CLASSES[type.to_sym] || "alert-info text-white"
  end

  def flash_icon(type)
    case type.to_sym
    when :alert, :error then "error"
    when :notice, :success then "success"
    else "info"
    end
  end
end
