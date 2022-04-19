# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210421140400_add_new_data_to_merge_requests_documents.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe AddNewDataToMergeRequestsDocuments do
  it_behaves_like 'a deprecated Advanced Search migration', 20210421140400
end
