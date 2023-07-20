# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230710142700_add_archived_to_merge_requests.rb')

RSpec.describe AddArchivedToMergeRequests, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230710142700 }

  include_examples 'migration adds mapping'
end
