# frozen_string_literal: true

FactoryBot.modify do
  factory :user_highest_role do
    trait(:minimal_access) { highest_access_level { GroupMember::MINIMAL_ACCESS } }
  end
end
