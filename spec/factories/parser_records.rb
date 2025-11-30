FactoryBot.define do
  factory :parser_record do
    filename { "MyString" }
    sender { "MyString" }
    parser_used { "MyString" }
    status { "MyString" }
    extracted_data { "" }
    error_message { "MyText" }
    customer { nil }
  end
end
