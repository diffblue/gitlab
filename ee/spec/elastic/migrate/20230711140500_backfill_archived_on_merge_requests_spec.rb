# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230711140500_backfill_archived_on_merge_requests.rb')

RSpec.describe BackfillArchivedOnMergeRequests, :elastic_delete_by_query, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230711140500 }

  include_examples 'migration backfills fields' do
    let_it_be(:project) { create(:project, archived: true) }
    let(:objects) { create_list(:merge_request, 3, :unique_branches, target_project: project, source_project: project) }
    let(:namespace) { project.namespace }
    let(:expected_fields) { { archived: project.archived? } }

    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
  end
end
