# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Search::Zoekt::Client, :zoekt, feature_category: :global_search do
  let_it_be(:project_1) { create(:project, :public, :repository) }
  let_it_be(:project_2) { create(:project, :public, :repository) }
  let_it_be(:project_3) { create(:project, :public, :repository) }
  let(:client) { described_class.new }

  shared_examples 'an authenticated zoekt request' do
    context 'when basicauth username and password are present' do
      let(:password_file) { Rails.root.join("tmp/tests/zoekt_password") }
      let(:username_file) { Rails.root.join("tmp/tests/zoekt_username") }

      before do
        username_file = Rails.root.join("tmp/tests/zoekt_username")
        File.write(username_file, "the-username\r") # Ensure trailing newline is ignored
        password_file = Rails.root.join("tmp/tests/zoekt_password")
        File.write(password_file, "the-password\r") # Ensure trailing newline is ignored
        stub_config(zoekt: { username_file: username_file, password_file: password_file })
      end

      after do
        File.delete(username_file)
        File.delete(password_file)
      end

      it 'sets those in the request' do
        expect(::Gitlab::HTTP).to receive(:post)
          .with(anything, hash_including(basic_auth: { username: 'the-username', password: 'the-password' }))
          .and_call_original

        make_request
      end
    end
  end

  describe '#search' do
    let(:project_ids) { [project_1.id, project_2.id] }
    let(:query) { 'use.*egex' }

    subject { client.search(query, num: 10, project_ids: project_ids) }

    before do
      zoekt_ensure_project_indexed!(project_1)
      zoekt_ensure_project_indexed!(project_2)
      zoekt_ensure_project_indexed!(project_3)
    end

    it 'returns the matching files from all searched projects' do
      expect(subject[:Result][:Files].pluck(:FileName)).to include(
        "files/ruby/regex.rb", "files/markdown/ruby-style-guide.md"
      )

      expect(subject[:Result][:Files].map { |r| r[:Repository].to_i }.uniq).to contain_exactly(
        project_1.id, project_2.id
      )
    end

    context 'when there is no project_id filter' do
      let(:project_ids) { [] }

      it 'raises an error if there are somehow no project_id in the filter' do
        expect do
          subject
        end.to raise_error('Not possible to search without at least one project specified')
      end
    end

    context 'with an invalid search' do
      let(:query) { '(invalid search(' }

      it 'logs an error and returns an empty array for results', :aggregate_failures do
        logger = instance_double(::Zoekt::Logger)
        expect(::Zoekt::Logger).to receive(:build).and_return(logger)
        expect(logger).to receive(:error).with(hash_including(status: 400))

        expect(subject[:Error]).to include("error parsing regexp")
      end
    end

    it_behaves_like 'an authenticated zoekt request' do
      let(:make_request) { subject }
    end
  end

  describe '#index' do
    it 'indexes the project to make it searchable' do
      search_results = client.search('use.*egex', num: 10, project_ids: [project_1.id])
      expect(search_results[:Result][:Files].to_a.size).to eq(0)

      client.index(project_1)

      search_results = client.search('use.*egex', num: 10, project_ids: [project_1.id])
      expect(search_results[:Result][:Files].to_a.size).to be > 0
    end

    context 'when use_new_zoekt_indexer is disabled' do
      before do
        stub_feature_flags(use_new_zoekt_indexer: false)
      end

      it 'indexes using the old path' do
        expect(::Gitlab::HTTP).to receive(:post) do |url, args|
          body = args[:body]
          expect(url.to_s).to eq("#{::Zoekt::Shard.first.index_base_url}/index")
          body = ::Gitlab::Json.parse(body)

          expect(body["CloneUrl"]).to be_present
          expect(body["RepoId"]).to eq(project_1.id)
        end.and_return({})

        described_class.instance.index(project_1)
      end
    end

    it 'raises an exception when indexing errors out' do
      allow(::Gitlab::HTTP).to receive(:post).and_return({ 'Error' => 'command failed: exit status 128' })

      expect do
        client.index(project_1)
      end.to raise_error(RuntimeError, 'command failed: exit status 128')
    end

    it 'raises an exception when response is not successful' do
      response = {}
      allow(response).to receive(:success?).and_return(false)

      allow(::Gitlab::HTTP).to receive(:post).and_return(response)

      expect { client.index(project_1) }.to raise_error(RuntimeError, /Request failed with/)
    end

    it 'sets http the correct timeout' do
      response = {}
      allow(response).to receive(:success?).and_return(true)

      expect(::Gitlab::HTTP).to receive(:post)
                                .with(anything, hash_including(timeout: described_class::INDEXING_TIMEOUT_S))
                                .and_return(response)

      client.index(project_1)
    end

    it_behaves_like 'an authenticated zoekt request' do
      let(:make_request) { client.index(project_1) }
    end
  end

  describe '#truncate' do
    it 'removes all data from the Zoekt shard' do
      client.index(project_1)
      search_results = client.search('use.*egex', num: 10, project_ids: [project_1.id])
      expect(search_results[:Result][:Files].to_a.size).to be > 0

      client.truncate

      search_results = client.search('use.*egex', num: 10, project_ids: [project_1.id])
      expect(search_results[:Result][:Files].to_a.size).to eq(0)
    end

    it_behaves_like 'an authenticated zoekt request' do
      let(:make_request) { client.truncate }
    end
  end
end
