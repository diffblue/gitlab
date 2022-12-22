# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ScannerPolicy, feature_category: :vulnerability_management do
  describe 'read_vulnerability_scanner' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:vulnerability_scanner) { create(:vulnerabilities_scanner, project: project) }

    subject { described_class.new(user, vulnerability_scanner) }

    context 'when the security_dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context "when the current user has developer access to the vulnerability's project" do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_allowed(:read_vulnerability_scanner) }
      end

      context "when the current user does not have developer access to the vulnerability's project" do
        it { is_expected.to be_disallowed(:read_vulnerability_scanner) }
      end
    end

    context 'when the security_dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)

        project.add_developer(user)
      end

      it { is_expected.to be_disallowed(:read_vulnerability_scanner) }
    end
  end
end
