class CustomersController < ApplicationController
  def index
    @pagy, @records = pagy(Customer.recent)
  end

  def show
    @record = Customer.find(params[:id])
    @records = @record.parser_records.recent
  end
end
