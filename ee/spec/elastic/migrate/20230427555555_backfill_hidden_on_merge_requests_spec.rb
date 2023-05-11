# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230427555555_backfill_hidden_on_merge_requests.rb')

RSpec.describe BackfillHiddenOnMergeRequests, :elastic_delete_by_query, feature_category: :global_search do
  let(:version) { 20230427555555 }

  include_examples 'migration backfills fields' do
    let(:objects) { create_list(:merge_request, 3) }
    let(:expected_fields) { { hidden: false } }

    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
  end
end
