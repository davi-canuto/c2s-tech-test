class CustomersController < ApplicationController
  before_action :set_record, only: [ :show, :destroy ]

  def index
    @pagy, @records = pagy(Customer.recent)
  end

  def show
    @parser_records = @record.parser_records.recent
  end

  def destroy
    if @record.destroy
      redirect_to customers_path, notice: t("flash.customers.destroyed")
    else
      redirect_to customer_path(@record), alert: t("flash.customers.destroy_failed")
    end
  end

  private

  def set_record
    @record = Customer.find(params[:id])
  end
end
