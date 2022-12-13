# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ExternalIssueLinkPolicy, feature_category: :vulnerability_management do
  let!(:user) { create(:user) }
  let!(:project) { create(:project) }
  let!(:vulnerability) { create(:vulnerability, project: project) }
  let!(:vulnerability_external_issue_link) { build(:vulnerabilities_external_issue_link, vulnerability: vulnerability, author: user) }

  subject { described_class.new(user, vulnerability_external_issue_link) }

  context 'when the security_dashboard feature is enabled' do
    before do
      stub_licensed_features(security_dashboard: true)
    end

    context "when the current user has developer access to the vulnerability's project" do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_allowed(:admin_vulnerability_external_issue_link) }
    end

    context "when the current user does not have developer access to the vulnerability's project" do
      it { is_expected.to be_disallowed(:admin_vulnerability_external_issue_link) }
    end
  end

  context 'when the security_dashboard feature is disabled' do
    before do
      stub_licensed_features(security_dashboard: false)

      project.add_developer(user)
    end

    it { is_expected.to be_disallowed(:admin_vulnerability_external_issue_link) }
  end
end
