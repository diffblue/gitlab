# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230203122938_backfill_internal_on_notes.rb')

RSpec.describe BackfillInternalOnNotes, :elastic_clean, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230203122938 }

  include_examples 'migration backfills fields' do
    let(:objects) { create_list(:note, 3, confidential: true) }
    let(:expected_fields) { { internal: true, confidential: true } }

    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
  end
end
