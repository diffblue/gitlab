# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MavenPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:package) { create(:maven_package, project: project, name: project.full_path) }
  let_it_be(:maven_metadatum) { package.maven_metadatum }
  let_it_be(:package_file) { package.package_files.with_file_name_like('%.xml').first }

  let(:headers) { { 'Private-Token' => personal_access_token.token } }

  before do
    group.add_maintainer(user)
  end

  describe 'GET /api/v4/groups/:id/-/packages/maven/*path/:file_name' do
    let(:url) { "/groups/#{group.id}/-/packages/maven/#{maven_metadatum.path}/#{package_file.file_name}" }

    subject { get api(url), headers: headers }

    it_behaves_like 'applying ip restriction for group'
  end

  describe 'GET /api/v4/projects/:id/packages/maven/*path/:file_name' do
    let(:url) { "/projects/#{project.id}/packages/maven/#{maven_metadatum.path}/#{package_file.file_name}" }

    subject { get api(url), headers: headers }

    it_behaves_like 'applying ip restriction for group'
  end
end
