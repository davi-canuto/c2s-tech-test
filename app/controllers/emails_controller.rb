class EmailsController < ApplicationController
  MAX_FILE_SIZE = 10.megabytes

  def new
  end

  def create
    unless email_file_param
      flash[:alert] = t('flash.emails.file_required')
      redirect_to new_email_path
      return
    end

    file = email_file_param

    unless valid_file?(file)
      redirect_to new_email_path
      return
    end

    parser_record = ParserRecord.new(
      filename: file.original_filename,
      status: :pending
    )

    parser_record.email_file.attach(
      io: file.open,
      filename: file.original_filename,
      content_type: file.content_type
    )

    if parser_record.save
      flash[:notice] = t('flash.emails.upload_success')
      redirect_to parser_records_path
    else
      flash[:alert] = t('flash.emails.upload_failed', errors: parser_record.errors.full_messages.join(', '))
      redirect_to new_email_path
    end
  end

  private

  def email_file_param
    params.permit(:email_file)[:email_file]
  end

  def valid_file?(file)
    unless file.original_filename.end_with?('.eml')
      flash[:alert] = t('flash.emails.invalid_format')
      return false
    end

    if file.size > MAX_FILE_SIZE
      flash[:alert] = t('flash.emails.file_too_large', max_size: '10MB')
      return false
    end

    true
  end
end
