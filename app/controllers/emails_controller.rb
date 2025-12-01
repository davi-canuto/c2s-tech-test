class EmailsController < ApplicationController
  def new
  end

  def create
    service = UploadEmailService.new(record_params)
    result = service.call

    if result
      flash[:notice] = t('flash.emails.upload_success')
      redirect_to parser_records_path
    else
      flash[:alert] = service.error_message
      redirect_to new_email_path
    end
  end

  private

  def record_params
    params.permit(:email_file)
  end
end
