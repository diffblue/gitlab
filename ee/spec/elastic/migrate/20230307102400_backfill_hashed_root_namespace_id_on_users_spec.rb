# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230321154100_backfill_hashed_root_namespace_id_on_users.rb')

RSpec.describe BackfillHashedRootNamespaceIdOnUsers, :elastic_delete_by_query, feature_category: :global_search do
  let(:version) { 20230321154100 }

  include_examples 'migration backfills fields' do
    let(:user) { create(:user) }
    let(:objects) { [user] }
    let(:expected_fields) do
      {
        hashed_root_namespace_id: user.namespace.hashed_root_namespace_id
      }
    end

    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
  end
end
