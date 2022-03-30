# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Repository::BlobType do
  specify { expect(described_class.graphql_name).to eq('RepositoryBlob') }
  specify { expect(described_class).to have_graphql_field(:code_owners, calls_gitaly?: true) }
end
