class CreateCustomer
  attr_reader :customer, :errors

  def initialize(data)
    @data = data
    @customer = nil
    @errors = []
  end

  def call
    @customer = Customer.new(
      name: @data[:name],
      email: @data[:email],
      phone: @data[:phone],
      product_code: @data[:product_code],
      email_subject: @data[:subject]
    )

    if @customer.save
      @customer
    else
      @errors = @customer.errors.full_messages
      nil
    end
  end

  def call!
    call || raise(ActiveRecord::RecordInvalid, @customer)
  end

  def success?
    @customer&.persisted?
  end
end
