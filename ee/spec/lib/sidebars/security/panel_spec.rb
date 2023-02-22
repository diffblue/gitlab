# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Security::Panel, feature_category: :navigation do
  let_it_be(:user) { create(:user) }
  let_it_be(:gitlab_logo_path) { ActionController::Base.helpers.image_path('logo.svg') }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  it 'renders the correct ARIA label' do
    expect(subject.aria_label).to be _("Security navigation")
  end

  it 'renders the correct header partial' do
    expect(subject.render_raw_scope_menu_partial).to be 'shared/nav/security_scope_header'
  end

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq({
      title: 'Security',
      avatar: gitlab_logo_path
    })
  end
end
