# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability_state_transition, class: 'Vulnerabilities::StateTransition' do
    vulnerability
    from_state { ::Enums::Vulnerability.vulnerability_states.keys[0] }
    to_state { ::Enums::Vulnerability.vulnerability_states.keys[1] }
    comment { "a comment on StateTransition object" }

    trait :from_detected do
      from_state { ::Enums::Vulnerability.vulnerability_states[:detected] }
    end

    trait :to_dismissed do
      to_state { ::Enums::Vulnerability.vulnerability_states[:dismissed] }
    end

    trait :used_in_tests do
      dismissal_reason { "used_in_tests" }
    end
  end
end
