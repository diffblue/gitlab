# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20221124090600_add_namespace_ancestry_ids_to_original_index_mapping.rb')

RSpec.describe AddNamespaceAncestryIdsToOriginalIndexMapping, :elastic, :sidekiq_inline,
feature_category: :global_search do
  let(:version) { 20221124090600 }

  include_examples 'migration adds mapping'
end
