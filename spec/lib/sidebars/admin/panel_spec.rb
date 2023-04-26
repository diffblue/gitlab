# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Panel, feature_category: :navigation do
  let_it_be(:user) { build(:admin) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  before do
    stub_licensed_features(
      admin_audit_log: true,
      custom_file_templates: true,
      elastic_search: true,
      license_scanning: true
    )
  end

  subject { described_class.new(context) }

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq({ title: 'Admin Area' })
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel without placeholders in EE'
end
