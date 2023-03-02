# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20220825102900_backfill_label_ids_for_issues.rb')

RSpec.describe BackfillLabelIdsForIssues, :elastic_delete_by_query, feature_category: :global_search do
  let(:version) { 20220825102900 }

  include_examples 'migration backfills fields' do
    let(:label) { create(:label) }
    let(:objects) { create_list(:labeled_issue, 3, labels: [label]) }
    let(:expected_fields) { { label_ids: [label.id.to_s], schema_version: 22_08 } }

    let(:expected_throttle_delay) { 3.minutes }
    let(:expected_batch_size) { 5000 }
  end
end
