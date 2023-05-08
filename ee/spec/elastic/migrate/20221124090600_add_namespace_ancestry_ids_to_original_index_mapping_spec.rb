# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20221124090600_add_namespace_ancestry_ids_to_original_index_mapping.rb')

RSpec.describe AddNamespaceAncestryIdsToOriginalIndexMapping, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20221124090600
end
