# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20210910094600_add_namespace_ancestry_ids_to_issues_mapping.rb')

RSpec.describe AddNamespaceAncestryIdsToIssuesMapping, :elastic, :sidekiq_inline do
  let(:version) { 20210910094600 }

  include_examples 'migration adds mapping'
end
