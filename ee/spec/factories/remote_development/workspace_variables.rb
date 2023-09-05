# frozen_string_literal: true

FactoryBot.define do
  factory :workspace_variable, class: 'RemoteDevelopment::WorkspaceVariable' do
    workspace

    key { 'my_key' }
    value { 'my_value' }
    variable_type { RemoteDevelopment::Workspaces::Create::WorkspaceVariables::VARIABLE_TYPE_FILE }
  end
end
