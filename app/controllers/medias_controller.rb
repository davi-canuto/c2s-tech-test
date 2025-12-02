class MediasController < ApplicationController
  before_action :set_record, only: [ :show ]

  def index
    @q = Media.ransack(params[:q])
    @pagy, @medias = pagy(
      @q.result(
        distinct: true
      ).includes(
        parser_records: :customer
      ).recent,
      limit: 20
    )
  end

  def show
    @parser_records = @media.parser_records.includes(:customer).recent
  end

  private

  def set_record
    @media = Media.find(params[:id])
  end
end
