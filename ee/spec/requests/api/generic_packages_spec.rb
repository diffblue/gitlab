# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GenericPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:package) { create(:generic_package, project: project) }
  let_it_be(:package_file) { create(:package_file, :generic, package: package) }

  let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

  before do
    group.add_maintainer(user)
  end

  describe 'GET /api/v4/projects/:id/packages/generic/:package_name/:package_version/:file_name' do
    let(:url) do
      "/projects/#{project.id}/packages/generic/#{package.name}/#{package.version}/#{package_file.file_name}"
    end

    subject { get api(url), headers: headers }

    it_behaves_like 'applying ip restriction for group'
  end
end
