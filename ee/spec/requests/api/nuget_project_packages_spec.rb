# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NugetProjectPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:package_name) { 'Dummy.Package' }
  let_it_be(:package) { create(:nuget_package, :with_symbol_package, project: project, name: package_name) }
  let_it_be(:version) { package.version }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

  before do
    group.add_maintainer(user)
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/download/*package_name/*package_version/*package_filename' do
    let(:url) do
      "/projects/#{project.id}/packages/nuget/download/#{package.name}/#{version}/#{package.name}.#{version}.nupkg"
    end

    subject { get api(url), headers: headers }

    it_behaves_like 'applying ip restriction for group'
  end
end
