# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230111142636_add_internal_to_notes.rb')

RSpec.describe AddInternalToNotes, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230111142636 }

  include_examples 'migration adds mapping'
end
