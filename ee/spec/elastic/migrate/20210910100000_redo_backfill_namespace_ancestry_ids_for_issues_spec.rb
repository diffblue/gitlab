# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20210910100000_redo_backfill_namespace_ancestry_ids_for_issues.rb')

RSpec.describe RedoBackfillNamespaceAncestryIdsForIssues, :elastic, :sidekiq_inline do
  let(:version) { 20210910100000 }

  include_examples 'migration backfills a field' do
    let(:objects) { create_list(:issue, 3) }
    let(:field_name) { :namespace_ancestry_ids }
    let(:field_value) { "1-2-3-" }

    let(:expected_throttle_delay) { 3.minutes }
    let(:expected_batch_size) { 5000 }
  end
end
