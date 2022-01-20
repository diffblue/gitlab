# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectSecurityTraining'] do
  let(:fields) { %i[id name description url logo_url is_enabled is_primary] }

  it { expect(described_class).to have_graphql_fields(fields) }
end
