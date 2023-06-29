# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230628094243_add_archived_to_issues.rb')

RSpec.describe AddArchivedToIssues, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230628094243 }

  include_examples 'migration adds mapping'
end
