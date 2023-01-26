# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability_state_transitions, class: 'Vulnerabilities::StateTransition' do
    vulnerability
    from_state { ::Enums::Vulnerability.vulnerability_states.keys[0] }
    to_state { ::Enums::Vulnerability.vulnerability_states.keys[1] }
  end
end
