# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::RepositoryImporter, feature_category: :importers do
  let_it_be(:project) { create(:project, import_url: 'http://bitbucket:test@my-bitbucket') }

  subject(:importer) { described_class.new(project) }

  describe '#execute' do
    it 'validates repository size' do
      allow(project.repository).to receive(:import_repository)
      allow(project.repository).to receive(:fetch_as_mirror)

      expect_next_instance_of(::Import::ValidateRepositorySizeService, project) do |service|
        expect(service).to receive(:execute)
      end

      importer.execute
    end
  end
end
