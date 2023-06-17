# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::RepositoryImporter, feature_category: :importers do
  let(:project) { build_stubbed(:project) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  subject(:importer) { described_class.new(project, client) }

  describe '#import_repository' do
    it 'validates repository size' do
      allow(project).to receive(:ensure_repository)
      allow(project).to receive_message_chain(:repository, :fetch_as_mirror)
      allow(client).to receive(:repository).and_return({})

      expect_next_instance_of(::Import::ValidateRepositorySizeService, project) do |service|
        expect(service).to receive(:execute)
      end

      importer.import_repository
    end
  end
end
