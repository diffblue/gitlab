# frozen_string_literal: true

FactoryBot.modify do
  factory :credit_card_validation do
    user
    sequence(:credit_card_validated_at) { |n| Time.current + n }
    expiration_date { 1.year.from_now.end_of_month }
    last_digits { 10 }
    holder_name { 'John Smith' }
    network { 'AmericanExpress' }
  end
end
