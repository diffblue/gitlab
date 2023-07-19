# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AccessLevelGroup'], feature_category: :source_code_management do
  include GraphqlHelpers

  subject { described_class }

  let(:expected_fields) { %w[id name web_url avatar_url parent] }

  it { is_expected.to require_graphql_authorizations(:read_group) }
  it { is_expected.to have_graphql_fields(expected_fields).only }
end
