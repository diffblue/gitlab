# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Namespace'] do
  it 'has specific fields' do
    expected_fields = %w[
      additional_purchased_storage_size
      total_repository_size_excess
      total_repository_size
      contains_locked_projects
      repository_size_excess_project_count
      actual_repository_size_limit
      storage_size_limit
      is_temporary_storage_increase_enabled
      temporary_storage_increase_ends_on
      compliance_frameworks
      scan_execution_policies
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'Customized fields' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, additional_purchased_storage_size: 100, repository_size_limit: 10_240) }
    let_it_be(:group_member) { create(:group_member, group: group, user: user) }
    let_it_be(:query) do
      %(
        query {
          namespace(fullPath: "#{group.full_path}") {
            additionalPurchasedStorageSize
            containsLockedProjects
            actualRepositorySizeLimit
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    it "returns the expected values for customized fields defined in NamespaceType" do
      namespace = subject.dig('data', 'namespace')

      expect(namespace['additionalPurchasedStorageSize']).to eq(100.megabytes)
      expect(namespace['containsLockedProjects']).to eq(false)
      expect(namespace['actualRepositorySizeLimit']).to eq(10_240)
    end
  end
end
