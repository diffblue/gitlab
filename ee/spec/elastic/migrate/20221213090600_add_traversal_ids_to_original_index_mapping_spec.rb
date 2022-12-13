# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20221213090600_add_traversal_ids_to_original_index_mapping.rb')

RSpec.describe AddTraversalIdsToOriginalIndexMapping, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20221213090600 }

  include_examples 'migration adds mapping'
end
