# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Git LFS File Locking API', :saas, feature_category: :source_code_management do
  include LfsHttpHelpers
  include NamespaceStorageHelpers

  let_it_be(:namespace, refind: true) { create(:namespace) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:developer) { create(:user) }
  let(:size_checker) { Namespaces::Storage::RootSize.new(namespace) }
  let(:user) { developer }
  let(:headers) do
    {
      'Authorization' => authorize_user
    }.compact
  end

  before_all do
    create(:gitlab_subscription, :ultimate, namespace: namespace)
    create(:namespace_root_storage_statistics, namespace: namespace)
  end

  before do
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)

    enforce_namespace_storage_limit(namespace)
    set_storage_size_limit(namespace, megabytes: 10)
    set_used_storage(namespace, megabytes: 11)

    project.add_developer(developer)
  end

  describe 'Create File Lock endpoint' do
    let(:url) { "#{project.http_url_to_repo}/info/lfs/locks" }
    let(:body) { { path: 'README.md' } }

    context 'with an exceeded namespace storage limit' do
      it 'does not create the lock' do
        post_lfs_json url, body, headers

        expect(response).to have_gitlab_http_status(:not_acceptable)

        expect(json_response['message']).to eq(size_checker.error_message.push_error)
      end
    end
  end

  describe 'Listing File Locks endpoint' do
    let(:url) { "#{project.http_url_to_repo}/info/lfs/locks" }

    context 'with an exceeded namespace storage limit' do
      it 'returns the list of locked files' do
        lock_file('README', developer)

        do_get url, nil, headers

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['locks'].size).to eq(1)
        expect(json_response['locks'].first.keys).to match_array(%w(id path locked_at owner))
      end
    end
  end

  describe 'List File Locks for verification endpoint' do
    let(:url) { "#{project.http_url_to_repo}/info/lfs/locks/verify" }

    context 'with an exceeded namespace storage limit' do
      it 'rejects the request' do
        lock_file('README', developer)

        post_lfs_json url, nil, headers

        expect(response).to have_gitlab_http_status(:not_acceptable)

        expect(json_response['message']).to eq(size_checker.error_message.push_error)
      end
    end
  end

  describe 'Delete File Lock endpoint' do
    let!(:lock) { lock_file('README.md', developer) }
    let(:url) { "#{project.http_url_to_repo}/info/lfs/locks/#{lock[:id]}/unlock" }

    context 'with an exceeded namespace storage limit' do
      it 'does not delete the lock' do
        post_lfs_json url, nil, headers

        expect(response).to have_gitlab_http_status(:not_acceptable)

        expect(json_response['message']).to eq(size_checker.error_message.push_error)
      end
    end
  end

  def lock_file(path, author)
    result = Lfs::LockFileService.new(project, author, { path: path }).execute

    result[:lock]
  end

  def do_get(url, params = nil, headers = nil)
    get(url, params: (params || {}), headers: (headers || {}).merge('Content-Type' => LfsRequest::CONTENT_TYPE))
  end
end
