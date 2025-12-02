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
    parser_record = ParserRecord.create!(
      filename: @media.filename,
      status: :pending,
      media: @media
    )

    redirect_to media_path(@media), notice: t("flash.emails.reprocess_started")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to media_path(@media), alert: "Failed to reprocess: #{e.message}"
  end

  private

  def record_params
    params.permit(:email_file)
  end

  def set_media
    @media = Media.find(params[:id])
  end
end
