# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['LicenseHistoryEntry'], :enable_admin_mode do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:licensee) do
    {
      'Name' => 'User Example',
      'Email' => 'user@example.com',
      'Company' => 'Example Inc.'
    }
  end

  let_it_be(:license) { create_current_license(licensee: licensee, cloud_licensing_enabled: true) }

  def query(field_name)
    %(
      {
        licenseHistoryEntries {
          nodes {
            #{field_name}
          }
        }
      }
    )
  end

  def query_field(field_name)
    GitlabSchema.execute(query(field_name), context: { current_user: admin }).as_json
  end

  it { expect(described_class.graphql_name).to eq('LicenseHistoryEntry') }

  include_examples 'license type fields'
end
