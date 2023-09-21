# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MemberRole'], feature_category: :system_access do
  let(:fields) { %w[description id name] }

  specify { expect(described_class.graphql_name).to eq('MemberRole') }

  specify { expect(described_class).to have_graphql_fields(fields) }

  specify { expect(described_class).to require_graphql_authorizations(:read_group_member) }
end
