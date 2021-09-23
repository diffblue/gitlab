# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20210813134600_add_namespace_ancestry_to_issues_mapping.rb')

RSpec.describe AddNamespaceAncestryToIssuesMapping, :elastic, :sidekiq_inline do
  let(:version) { 20210813134600 }

  include_examples 'migration adds mapping'
end
