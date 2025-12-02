FactoryBot.define do
  factory :parser_record do
    sequence(:filename) { |n| "email_#{n}.eml" }
    sender { Faker::Internet.email }
    parser_used { nil }
    status { :pending }
    extracted_data { {} }
    error_message { nil }
    customer { nil }
    media { nil }

    trait :with_media do
      media { association :media }
    end

    trait :successful do
      status { :success }
      parser_used { "Parsers::ExampleParser" }
      extracted_data { { name: Faker::Name.name, email: Faker::Internet.email } }
    end

    trait :failed do
      status { :failed }
      error_message { "Failed to parse email" }
    end
  end
end
