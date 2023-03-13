# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::StateTransitionPolicy, feature_category: :vulnerability_management do
  describe 'read_security_resource' do
    let(:user) { create(:user) }
    let(:state_transition) { create(:vulnerability_state_transition) }

    subject { described_class.new(user, state_transition) }

    context 'when the security_dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context "when the current user is not a project member" do
        it { is_expected.to be_disallowed(:read_security_resource) }
      end

      context "when the current user has developer access to the vulnerability's project" do
        before do
          state_transition.vulnerability.project.add_developer(user)
        end

        it { is_expected.to be_allowed(:read_security_resource) }
      end
    end

    context 'when the security_dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)

        state_transition.vulnerability.project.add_developer(user)
      end

      it { is_expected.to be_disallowed(:read_security_resource) }
    end
  end
end
