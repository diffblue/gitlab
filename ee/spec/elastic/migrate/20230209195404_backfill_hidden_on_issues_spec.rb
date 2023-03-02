# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230209195404_backfill_hidden_on_issues.rb')

RSpec.describe BackfillHiddenOnIssues, :elastic_delete_by_query, feature_category: :global_search do
  let(:version) { 20230209195404 }

  include_examples 'migration backfills fields' do
    let(:objects) { create_list(:issue, 3) }
    let(:expected_fields) { { hidden: false } }

    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
  end
end
