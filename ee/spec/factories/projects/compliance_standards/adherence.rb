# frozen_string_literal: true

FactoryBot.define do
  factory :compliance_standards_adherence, class: 'Projects::ComplianceStandards::Adherence' do
    association :project, factory: [:project, :in_group]
    namespace { project.namespace }
    status { :success }
    check_name { :prevent_approval_by_merge_request_author }
    standard { :gitlab }

    trait :gitlab do
      standard { :gitlab }
    end

    trait :fail do
      status { :fail }
    end
  end
end
