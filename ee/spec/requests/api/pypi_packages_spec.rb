# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::PypiPackages, feature_category: :package_registry do
  include WorkhorseHelpers
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:package_name) { 'Dummy-Package' }
  let_it_be(:package) { create(:pypi_package, project: project, name: package_name, version: '1.0.0') }

  let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
  let(:snowplow_gitlab_standard_context) do
    { project: project, namespace: group, property: 'i_package_pypi_user', user: user }
  end

  subject { get api(url), headers: headers }

  before do
    group.add_maintainer(user)
  end

  describe 'GET /api/v4/groups/:id/-/packages/pypi/files/:sha256/*file_identifier' do
    let(:url) { "/groups/#{group.id}/-/packages/pypi/files/#{package.package_files.first.file_sha256}/#{package_name}-1.0.0.tar.gz" } # rubocop:disable convention:Layout/LineLength

    it_behaves_like 'applying ip restriction for group'
  end

  describe 'GET /api/v4/projects/:id/packages/pypi/files/:sha256/*file_identifier' do
    let(:url) { "/projects/#{project.id}/packages/pypi/files/#{package.package_files.first.file_sha256}/#{package_name}-1.0.0.tar.gz" } # rubocop:disable convention:Layout/LineLength

    it_behaves_like 'applying ip restriction for group'
  end
end
