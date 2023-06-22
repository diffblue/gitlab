# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['RepositoryCodeownerValidation'], feature_category: :source_code_management do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('RepositoryCodeownerValidation') }

  specify do
    expect(::EE::Types::Repository::CodeOwnerValidationType).to have_graphql_fields(
      :total,
      :validation_errors
    ).at_least
  end
end
