FactoryBot.define do
  factory :media do
    sequence(:filename) { |n| "email_#{n}.eml" }
    file_size { 1024 }
    content_type { "message/rfc822" }
    sequence(:checksum) { |n| Digest::MD5.hexdigest("content_#{n}") }
    sender { Faker::Internet.email }
    subject { Faker::Lorem.sentence }
    original_date { Faker::Time.between(from: 1.year.ago, to: Time.current) }

    trait :with_file do
      after(:build) do |media|
        media.file.attach(
          io: StringIO.new("From: sender@example.com\nSubject: Test\n\nBody"),
          filename: media.filename,
          content_type: media.content_type
        )
      end
    end

    factory :media_with_file, traits: [ :with_file ]
  end
end
