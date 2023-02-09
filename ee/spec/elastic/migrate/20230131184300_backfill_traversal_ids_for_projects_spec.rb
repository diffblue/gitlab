# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230131184300_backfill_traversal_ids_for_projects.rb')

RSpec.describe BackfillTraversalIdsForProjects, :elastic_clean, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230131184300 }

  include_examples 'migration backfills fields' do
    let(:group) { create(:group) }
    let(:objects) { create_list(:project, 3, :repository, namespace: group) }

    let(:expected_fields) { { traversal_ids: "#{group.id}-" } }
    let(:expected_throttle_delay) { 3.minutes }
    let(:expected_batch_size) { 10_000 }

    before do
      create_list(:snippet, 3, :public)
    end
  end
end
