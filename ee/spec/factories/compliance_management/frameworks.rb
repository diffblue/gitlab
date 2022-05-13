# frozen_string_literal: true

FactoryBot.define do
  factory :compliance_framework, class: 'ComplianceManagement::Framework' do
    association :namespace, factory: :group

    name { 'GDPR' }
    description { 'The General Data Protection Regulation (GDPR) is a regulation in EU law on data protection and privacy in the European Union (EU) and the European Economic Area (EEA).' }
    color { '#004494' }

    trait :sox do
      name { 'SOX' }
    end

    trait :with_pipeline do
      pipeline_configuration_full_path { 'compliance.gitlab-ci.yml@test-project' }
    end
  end
end
