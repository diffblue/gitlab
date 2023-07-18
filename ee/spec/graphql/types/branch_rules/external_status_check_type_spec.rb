# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ExternalStatusCheck'], feature_category: :source_code_management do
  subject { described_class }

  let(:fields) { %i[id name external_url] }

  it { expect(described_class).to require_graphql_authorizations(:read_external_status_check) }

  it { expect(described_class).to have_graphql_fields(fields).only }
end
