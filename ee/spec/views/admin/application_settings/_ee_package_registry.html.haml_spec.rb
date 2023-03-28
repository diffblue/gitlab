# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_ee_package_registry.html.haml', feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { build(:admin) }
  let_it_be(:app_settings) { build(:application_setting) }

  subject { rendered }

  before do
    assign(:application_setting, app_settings)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'package registry settings' do
    it 'renders right description' do
      render

      expect(rendered).to have_content(
        s_(
          'PackageRegistry|Forward package requests to a public registry if the packages are not found in the ' \
          'GitLab package registry.'
        )
      )
      expect(rendered).to have_content(
        s_('PackageRegistry|There are security risks if packages are deleted while request forwarding is enabled.'))
      expect(rendered).to have_link('What are the risks?',
        href: help_page_path('user/packages/package_registry/supported_functionality', { anchor: 'deleting-packages' }))
    end
  end
end
