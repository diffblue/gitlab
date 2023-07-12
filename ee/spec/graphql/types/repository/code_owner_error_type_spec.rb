# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['RepositoryCodeownerError'], feature_category: :source_code_management do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('RepositoryCodeownerError') }

  specify do
    expect(::EE::Types::Repository::CodeOwnerErrorType).to have_graphql_fields(
      :code,
      :lines
    ).at_least
  end
end
