# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Panel, feature_category: :navigation do
  let_it_be(:user) { build(:admin) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  before do
    stub_licensed_features(
      custom_roles: true,
      admin_audit_log: true,
      custom_file_templates: true,
      elastic_search: true,
      license_scanning: true
    )
    stub_application_setting(grafana_enabled: true)
  end

  subject { described_class.new(context) }

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel without placeholders'
end
