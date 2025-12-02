class EmailsController < ApplicationController
  before_action :set_media, only: [ :reprocess ]

  def new
  end

  def create
    service = UploadEmailService.new(record_params)
    result = service.call

    if result
      flash[:notice] = t("flash.emails.upload_success")
      redirect_to parser_records_path
    else
      flash[:alert] = service.error_message
      redirect_to new_email_path
    end
  end

  def reprocess
    service = ReprocessEmailService.new(media: @media)
    result = service.call

    if result
      redirect_to media_path(@media), notice: t("flash.emails.reprocess_started")
    else
      redirect_to media_path(@media), alert: service.error_message
    end
  end

  private

  def record_params
    params.permit(:email_file)
  end

  def set_media
    @media = Media.find(params[:id])
  end
end
