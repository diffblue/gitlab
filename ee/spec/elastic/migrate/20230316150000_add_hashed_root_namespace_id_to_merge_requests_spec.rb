# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230316150000_add_hashed_root_namespace_id_to_merge_requests.rb')

RSpec.describe AddHashedRootNamespaceIdToMergeRequests, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230316150000 }

  include_examples 'migration adds mapping'
end
