# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230307102400_backfill_hashed_root_namespace_id_on_notes.rb')

RSpec.describe BackfillHashedRootNamespaceIdOnNotes, :elastic_delete_by_query, feature_category: :global_search do
  let(:version) { 20230307102400 }

  include_examples 'migration backfills fields' do
    let_it_be(:project) { create(:project) }
    let(:objects) { create_list(:note, 3, project: project) }
    let(:namespace) { project.namespace }
    let(:expected_fields) do
      {
        hashed_root_namespace_id: namespace.hashed_root_namespace_id
      }
    end

    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
  end
end
