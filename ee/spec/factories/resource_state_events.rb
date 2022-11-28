# frozen_string_literal: true

FactoryBot.modify do
  factory :resource_state_event do
    issue { nil }
    merge_request { nil }
    epic { issue.nil? && merge_request.nil? ? association(:epic) : nil }
    state { :opened }
    user { issue&.author || merge_request&.author || epic&.author || association(:user) }
  end
end
