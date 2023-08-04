# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230731225441_reindex_work_items_to_fix_archived.rb')

RSpec.describe ReindexWorkItemsToFixArchived, :elastic_delete_by_query, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230731225441 }

  include_examples 'migration reindex based on schema_version' do
    let_it_be(:project) { create(:project, archived: true) }
    let(:objects) { create_list(:work_item, 3, project: project) }
    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
  end
end
