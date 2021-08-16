# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::SamlProvidersHelper do
  def stub_can(permission, value)
    allow(helper).to receive(:can?).with(user, permission, group).and_return(value)
  end

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#show_saml_in_sidebar?' do
    subject { helper.show_saml_in_sidebar?(group) }

    context 'when the user can admin group saml' do
      before do
        stub_can(:admin_group_saml, true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when the user cannot admin group saml' do
      before do
        stub_can(:admin_group_saml, false)
      end

      it { is_expected.to eq(false) }
    end
  end
end
