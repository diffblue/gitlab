# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NpmProjectPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:package) { create(:npm_package, project: project) }

  let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

  before do
    group.add_maintainer(user)
  end

  describe 'GET /api/v4/projects/:id/packages/npm/*package_name/-/*file_name' do
    let(:package_file) { package.package_files.first }
    let(:url) { "/projects/#{project.id}/packages/npm/#{package.name}/-/#{package_file.file_name}" }

    subject { get api(url), headers: headers }

    it_behaves_like 'applying ip restriction for group'
  end
end
