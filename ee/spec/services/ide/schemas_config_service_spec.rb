# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ide::SchemasConfigService, feature_category: :web_ide do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:sha) { 'sha' }
  let(:filename) { 'sample.yml' }
  let(:schema_content) { double(body: '{"title":"Sample schema"}') }

  describe '#execute' do
    before do
      project.add_developer(user)

      allow(project.repository).to receive(:blob_data_at).with('sha', anything) do
        config_content
      end

      allow(Gitlab::HTTP).to receive(:get).with(anything) do
        schema_content
      end
    end

    subject { described_class.new(project, user, sha: sha, filename: filename).execute }

    context 'content is not valid' do
      let(:config_content) { 'invalid content' }

      it 'returns an error' do
        is_expected.to include(
          status: :error,
          message: "Invalid configuration format")
      end
    end

    context 'when a predefined schema exists for the given filename' do
      let(:filename) { '.gitlab-ci.yml' }

      context 'with valid config content' do
        let(:config_content) { 'schemas: [{uri: "https://someurl.com", match: ["*.yml"]}]' }

        it 'uses predefined schema matches' do
          expect(Gitlab::HTTP).to receive(:get).with('https://json.schemastore.org/gitlab-ci')
          expect(Gitlab::HTTP).not_to receive(:get).with('https://someurl.com')

          expect(subject[:schema]['title']).to eq "Sample schema"
        end
      end

      context 'with invalid config content' do
        let(:config_content) { '' }

        it 'uses predefined schema matches' do
          expect(Gitlab::HTTP).to receive(:get).with('https://json.schemastore.org/gitlab-ci')

          expect(subject[:schema]['title']).to eq "Sample schema"
        end
      end
    end

    context 'no schemas are defined' do
      let(:config_content) { '{}' }

      it 'returns success with an empty object' do
        is_expected.to include(
          status: :success,
          schema: {})
      end
    end

    context 'feature :ide_schema_config is not available' do
      let(:config_content) { 'schemas: [{uri: "https://someurl.com", match: ["*.yml"]}]' }

      it 'returns empty object, despite config being defined' do
        expect(Gitlab::HTTP).not_to receive(:get).with("https://someurl.com")
        expect(subject[:schema]).to eq({})
      end
    end

    context 'feature :ide_schema_config is available' do
      before do
        allow(project).to receive(:feature_available?).with(:ide_schema_config) { true }
      end

      context 'schemas are defined and a matching schema is found and valid' do
        let(:config_content) { 'schemas: [{uri: "https://someurl.com", match: ["*.yml"]}]' }

        it 'returns schema successfully' do
          expect(Gitlab::HTTP).to receive(:get).with("https://someurl.com")
          expect(subject[:schema]['title']).to eq "Sample schema"
        end
      end

      context 'schemas are defined and a matching schema is found and but the schema is not a valid JSON' do
        let(:config_content) { 'schemas: [{uri: "https://someurl.com", match: ["*.yml"]}]' }
        let(:schema_content) { double(body: 'invalid json!') }

        it 'returns schema successfully' do
          expect(Gitlab::HTTP).to receive(:get).with("https://someurl.com")
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to include('unexpected character (after ) at line 1, column 1')
        end
      end

      context 'schemas are defined and but no matching schema found' do
        let(:config_content) { 'schemas: [{uri: "https://someurl.com", match: ["*.json"]}]' }

        it 'returns empty schema object' do
          expect(Gitlab::HTTP).not_to receive(:get).with("https://someurl.com")
          expect(subject[:schema]).to eq({})
        end
      end

      context 'nested schema filename with "**" in match uri' do
        let(:config_content) { 'schemas: [{uri: "https://someurl.com", match: ["data/somepath/**/*.yml"]}]' }
        let(:filename) { 'data/somepath/unreleased/changelog/path/changelog.yml' }

        it 'returns schema successfully' do
          expect(Gitlab::HTTP).to receive(:get).with("https://someurl.com")
          expect(subject[:schema]['title']).to eq "Sample schema"
        end
      end
    end
  end
end
