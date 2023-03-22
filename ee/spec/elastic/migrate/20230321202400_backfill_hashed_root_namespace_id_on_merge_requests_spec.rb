# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230321202400_backfill_hashed_root_namespace_id_on_merge_requests.rb')

RSpec.describe BackfillHashedRootNamespaceIdOnMergeRequests, :elastic_delete_by_query, feature_category: :global_search do
  let(:version) { 20230321202400 }

  include_examples 'migration backfills fields' do
    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
    let(:objects) { create_list(:merge_request, 3) }
    let(:namespace) { objects.first.target_project.namespace }
    let(:expected_fields) do
      { hashed_root_namespace_id: namespace.hashed_root_namespace_id }
    end
  end
end
