module ServiceResult
  class Result
    attr_reader :customer, :parser_record, :error_message

    def initialize(success:, customer: nil, parser_record: nil, error_message: nil)
      @success = success
      @customer = customer
      @parser_record = parser_record
      @error_message = error_message
    end

    def success?
      @success
    end

    def failure?
      !@success
    end
  end

  class Success < Result
    def initialize(customer:, parser_record:)
      super(success: true, customer: customer, parser_record: parser_record)
    end
  end

  class Failure < Result
    def initialize(error_message:, parser_record: nil)
      super(success: false, error_message: error_message, parser_record: parser_record)
    end
  end
end
