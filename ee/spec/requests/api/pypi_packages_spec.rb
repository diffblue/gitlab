# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::PypiPackages do
  include WorkhorseHelpers
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :public, group: group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

  shared_examples 'with ip restriction' do
    before do
      allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
      stub_licensed_features(group_ip_restriction: true)
      group.add_maintainer(user)
    end

    context 'in group without restriction' do
      it_behaves_like 'PyPI package download', :maintainer, :success, true
    end

    context 'in group with restriction' do
      before do
        create(:ip_restriction, group: group, range: range)
      end

      context 'with address within the range' do
        let(:range) { '192.168.0.0/24' }

        it_behaves_like 'PyPI package download', :maintainer, :success, true
      end

      context 'with address outside the range' do
        let(:range) { '10.0.0.0/8' }

        it_behaves_like 'returning response status', :not_found
      end
    end
  end

  context 'for the file download endpoint' do
    let_it_be(:package_name) { 'Dummy-Package' }
    let_it_be(:package) { create(:pypi_package, project: project, name: package_name, version: '1.0.0') }

    subject { get api(url), headers: headers }

    describe 'GET /api/v4/groups/:id/-/packages/pypi/files/:sha256/*file_identifier' do
      let(:url) { "/groups/#{group.id}/-/packages/pypi/files/#{package.package_files.first.file_sha256}/#{package_name}-1.0.0.tar.gz" } # rubocop:disable convention:Layout/LineLength

      let(:snowplow_gitlab_standard_context) { {} }

      it_behaves_like 'with ip restriction'
    end

    describe 'GET /api/v4/projects/:id/packages/pypi/files/:sha256/*file_identifier' do
      let(:url) { "/projects/#{project.id}/packages/pypi/files/#{package.package_files.first.file_sha256}/#{package_name}-1.0.0.tar.gz" } # rubocop:disable convention:Layout/LineLength

      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace } }

      it_behaves_like 'with ip restriction'
    end
  end
end
