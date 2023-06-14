# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230607500000_backfill_milestone_permissions_to_milestone_documents.rb')

RSpec.describe BackfillMilestonePermissionsToMilestoneDocuments, :elastic_delete_by_query, feature_category: :global_search do
  let(:version) { 20230607500000 }

  include_examples 'migration backfills fields' do
    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 9000 }
    let(:objects) { create_list(:milestone, 3) }
    let(:namespace) { objects.first.project.namespace }
    let(:expected_fields) do
      {
        issues_access_level: objects.first.project.issues_access_level,
        merge_requests_access_level: objects.first.project.merge_requests_access_level,
        visibility_level: objects.first.project.visibility_level
      }
    end
  end
end
