# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230717132609_backfill_archived_on_work_items.rb')

RSpec.describe BackfillArchivedOnWorkItems, :elastic_delete_by_query, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230717132609 }

  include_examples 'migration backfills fields' do
    let_it_be(:project) { create(:project, archived: true) }
    let(:objects) { create_list(:work_item, 3, project: project) }
    let(:namespace) { project.namespace }
    let(:expected_fields) do
      {
        archived: project.archived?
      }
    end

    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
  end
end
