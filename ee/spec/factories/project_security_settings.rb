# frozen_string_literal: true

FactoryBot.define do
  factory :project_security_setting do
    project { association :project, security_setting: instance }
    auto_fix_container_scanning { true }
    auto_fix_dast { true }
    auto_fix_dependency_scanning { true }
    auto_fix_sast { true }

    trait :disabled_auto_fix do
      auto_fix_container_scanning { false }
      auto_fix_dast { false }
      auto_fix_dependency_scanning { false }
      auto_fix_sast { false }
    end
  end
end
