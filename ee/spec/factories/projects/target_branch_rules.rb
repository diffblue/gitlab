# frozen_string_literal: true

FactoryBot.define do
  factory :target_branch_rule, class: 'Projects::TargetBranchRule' do
    project
    target_branch { "master" }
    name { "dev" }
  end
end
