# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Elastic migration documentation', feature_category: :global_search do
  it 'has a dictionary record for every migration file' do
    migration_files = Dir.glob('ee/elastic/migrate/*.rb').map { |f| f.gsub('ee/elastic/migrate/', '').gsub('.rb', '') }
    dictionary_files = Dir.glob('ee/elastic/docs/*.yml').map { |f| f.gsub('ee/elastic/docs/', '').gsub('.yml', '') }

    missing_dictionary_records = migration_files - dictionary_files

    message = "Expected dictionary files to be present in ee/elastic/docs/ for migrations #{missing_dictionary_records}"
    expect(missing_dictionary_records).to be_empty, message
  end
end
