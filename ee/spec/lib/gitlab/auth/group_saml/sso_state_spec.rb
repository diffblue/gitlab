# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::SsoState do
  let(:saml_provider_id) { 10 }

  subject { described_class.new(saml_provider_id) }

  describe '#update_active' do
    it 'updates the current sign in state' do
      Gitlab::Session.with_session({}) do
        new_state = double
        subject.update_active(new_state)

        expect(Gitlab::Session.current[:active_group_sso_sign_ins]).to eq({ saml_provider_id => new_state })
      end
    end
  end

  describe '#active?' do
    it 'gets the current sign in state' do
      current_state = double

      Gitlab::Session.with_session(active_group_sso_sign_ins: { saml_provider_id => current_state }) do
        expect(subject.active?).to eq current_state
      end
    end
  end

  describe '#active_since?' do
    let(:cutoff) { 1.week.ago }

    it 'is always active in a sessionless request' do
      is_expected.to be_active_since(cutoff)
    end

    it 'is inactive if never signed in' do
      Gitlab::Session.with_session({}) do
        is_expected.not_to be_active_since(cutoff)
      end
    end

    it 'is active if signed in since the cut off' do
      time_after_cut_off = cutoff + 2.days

      Gitlab::Session.with_session(active_group_sso_sign_ins: { saml_provider_id => time_after_cut_off }) do
        is_expected.to be_active_since(cutoff)
      end
    end

    it 'is inactive if signed in before the cut off' do
      time_before_cut_off = cutoff - 2.days

      Gitlab::Session.with_session(active_group_sso_sign_ins: { saml_provider_id => time_before_cut_off }) do
        is_expected.not_to be_active_since(cutoff)
      end
    end
  end
end
