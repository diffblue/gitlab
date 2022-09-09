# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::FindingPolicy do
  describe 'read_security_resource' do
    let(:user) { create(:user) }
    let(:security_finding) { create(:security_finding) }

    subject { described_class.new(user, security_finding) }

    context 'when the security_dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context "when the current user is not a project member" do
        it { is_expected.to be_disallowed(:read_security_resource) }
      end

      context "when the current user has developer access to the vulnerability's project" do
        before do
          security_finding.project.add_developer(user)
        end

        it { is_expected.to be_allowed(:read_security_resource) }
      end
    end

    context 'when the security_dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)

        security_finding.project.add_developer(user)
      end

      it { is_expected.to be_disallowed(:read_security_resource) }
    end
  end
end
