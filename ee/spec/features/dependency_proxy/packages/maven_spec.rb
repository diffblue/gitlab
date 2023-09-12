# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dependency Proxy for maven packages', :js, :aggregate_failures, feature_category: :package_registry do
  include_context 'file upload requests helpers'
  include_context 'with a server running the dependency proxy'

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be_with_reload(:dependency_proxy_setting) do
    create(:dependency_proxy_packages_setting, :maven, project: project)
  end

  let_it_be(:remote_file_path) { '/foo/bar/1.2.3/foo.bar-1.2.3.pom' }
  let_it_be(:remote_file_content) { 'this is a pom file content' }

  let_it_be(:remote_server) do
    handler = ->(env) do
      # disabling rubocop warning as this is inside a lambda function
      if env['REQUEST_PATH'] == remote_file_path # rubocop: disable RSpec/AvoidConditionalStatements
        [200, {}, [remote_file_content]]
      else
        [400, {}, []]
      end
    end

    run_server(handler)
  end

  let(:url) { capybara_url("/api/v4/projects/#{project.id}/dependency_proxy/packages/maven#{remote_file_path}") }
  let(:headers) { { 'Private-Token' => personal_access_token.token } }
  let(:last_package) { ::Packages::Package.last }
  let(:last_package_file) { ::Packages::PackageFile.last }

  subject(:response) do
    HTTParty.get(url, headers: headers)
  end

  before do
    stub_licensed_features(dependency_proxy_for_packages: true)
    stub_config(dependency_proxy: { enabled: true })

    dependency_proxy_setting.update!(maven_external_registry_url: remote_server.base_url)
  end

  shared_examples 'pulling and caching the remote file' do
    it 'pulls and caches the remote file' do
      expect { response }
        .to change { project.packages.maven.count }.from(0).to(1)
        .and change { ::Packages::PackageFile.count }.from(0).to(1)
      expect(last_package.name).to eq('foo/bar')
      expect(last_package.version).to eq('1.2.3')
      expect(last_package_file.file_name).to eq('foo.bar-1.2.3.pom')
      expect(response.code).to eq(200)
      expect(response.body).to eq(remote_file_content)
    end
  end

  shared_examples 'returning the cached file' do
    it 'returns the cached file' do
      expect_next_instance_of(::DependencyProxy::Packages::Maven::VerifyPackageFileEtagService) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success)
      end
      expect(Gitlab::Workhorse).not_to receive(:send_url)
      expect(Gitlab::Workhorse).not_to receive(:send_dependency)
      expect { response }
        .to not_change { project.packages.maven.count }
        .and not_change { ::Packages::PackageFile.count }
      expect(response.code).to eq(200)
      expect(response.body).to eq(remote_file_content)
    end
  end

  shared_examples 'proxying the remote file if the wrong etag is returned' do
    include_context 'with a wrong etag returned' do
      it 'proxies the remote file' do
        expect(Gitlab::Workhorse).to receive(:send_url).and_call_original
        expect(Gitlab::Workhorse).not_to receive(:send_dependency).and_call_original
        expect { response }
          .to not_change { project.packages.maven.count }
          .and not_change { ::Packages::PackageFile.pending_destruction.count }
        expect(response.code).to eq(200)
        expect(response.body).to eq(remote_file_content)
      end
    end
  end

  shared_context 'with an existing cached file' do
    let_it_be(:package) { create(:maven_package, name: 'foo/bar', version: '1.2.3', project: project) }
    let_it_be_with_reload(:package_file) { package.package_files.find { |f| f.file_name.end_with?('.pom') } }

    before do
      file = CarrierWaveStringFile.new_file(
        file_content: remote_file_content,
        filename: 'foo.bar-1.2.3.pom',
        content_type: 'text/plain'
      )
      package_file.update!(file_name: 'foo.bar-1.2.3.pom', file: file)
      package.maven_metadatum.update!(path: 'foo/bar/1.2.3')
    end
  end

  shared_context 'with a wrong etag returned' do
    before do
      allow_next_instance_of(::DependencyProxy::Packages::Maven::VerifyPackageFileEtagService) do |service|
        allow(service).to receive(:execute).and_return(ServiceResponse.error(message: '', reason: :wrong_etag))
      end
    end
  end

  context 'with a reporter' do
    before_all do
      project.add_reporter(user)
    end

    context 'with no existing file' do
      it 'pulls the remote file without caching' do
        expect { response }
          .to not_change { project.packages.maven.count }
          .and not_change { ::Packages::PackageFile.count }
        expect(response.code).to eq(200)
        expect(response.body).to eq(remote_file_content)
      end
    end

    context 'with existing file' do
      include_context 'with an existing cached file'

      it_behaves_like 'returning the cached file'
      it_behaves_like 'proxying the remote file if the wrong etag is returned'
    end
  end

  context 'with a developer' do
    before_all do
      project.add_developer(user)
    end

    context 'with no existing file' do
      it_behaves_like 'pulling and caching the remote file'
    end

    context 'with existing file' do
      include_context 'with an existing cached file'

      it_behaves_like 'returning the cached file'
      it_behaves_like 'proxying the remote file if the wrong etag is returned'
    end
  end

  context 'with a maintainer' do
    before_all do
      project.add_maintainer(user)
    end

    context 'with no existing file' do
      it_behaves_like 'pulling and caching the remote file'
    end

    context 'with existing file' do
      include_context 'with an existing cached file'

      it_behaves_like 'returning the cached file'

      include_context 'with a wrong etag returned' do
        it 'deletes the cached file and proxy the remote file' do
          expect(Gitlab::Workhorse).not_to receive(:send_url)
          expect(Gitlab::Workhorse).to receive(:send_dependency).and_call_original
          expect { response }
            .to not_change { project.packages.maven.count }
            .and change { ::Packages::PackageFile.pending_destruction.count }.from(0).to(1)
          expect(response.code).to eq(200)
          expect(response.body).to eq(remote_file_content)
        end
      end
    end
  end
end
