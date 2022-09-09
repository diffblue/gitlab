# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Attachments::BaseImporter do
  let(:importer_class) do
    Class.new(described_class) do
      def self.name
        'MyImporter'
      end

      def private_collection
        collection
      end
    end
  end

  let(:project) { instance_double(Project) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let(:importer) { importer_class.new(project, client) }

  describe 'private interfaces' do
    describe '#collection' do
      it { expect { importer.private_collection }.to raise_error(NotImplementedError) }
    end
  end
end
