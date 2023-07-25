# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230722212041_backfill_archived_on_notes.rb')

RSpec.describe BackfillArchivedOnNotes, :elastic_delete_by_query, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230722212041 }

  include_examples 'migration backfills fields' do
    let_it_be(:project) { create(:project, archived: true) }
    let(:objects) { create_list(:note, 3, project: project) }
    let(:namespace) { project.namespace }
    let(:expected_fields) do
      { archived: project.archived? }
    end

    let(:expected_throttle_delay) { 10.seconds }
    let(:expected_batch_size) { 9000 }
  end
end
