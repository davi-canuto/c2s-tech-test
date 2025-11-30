class ParserRecordsController < ApplicationController
  def index
    @q = ParserRecord.ransack(params[:q])
    @pagy, @records = pagy(@q.result.recent)
    @senders = ParserRecord.distinct_senders
  end

  def show
    @record = ParserRecord.find(params[:id])
  end
end
