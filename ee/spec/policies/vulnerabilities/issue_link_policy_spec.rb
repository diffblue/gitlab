# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::IssueLinkPolicy, feature_category: :vulnerability_management do
  let(:vulnerability_issue_link) { build(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let_it_be(:vulnerability) { create(:vulnerability, project: project) }
  let_it_be(:issue) { create(:issue, project: project) }

  subject { described_class.new(user, vulnerability_issue_link) }

  describe ':admin_vulnerability_issue_link' do
    before do
      stub_licensed_features(security_dashboard: true)

      project.add_developer(user)
    end

    context 'with missing vulnerability' do
      let_it_be(:vulnerability) { nil }
      let_it_be(:issue) { create(:issue) }

      it { is_expected.to be_disallowed(:admin_vulnerability_issue_link) }
    end

    context 'when issue and link belong to the same project' do
      it { is_expected.to be_allowed(:admin_vulnerability_issue_link) }
    end

    context "when issue and link don't belong to the same project" do
      let_it_be(:issue) { create(:issue) }

      it { is_expected.to be_allowed(:admin_vulnerability_issue_link) }
    end
  end

  describe ':read_issue_link' do
    before do
      allow(Ability).to receive(:allowed?).with(user, :read_issue, issue).and_return(allowed?)
    end

    context 'when the associated issue can not be read by the user' do
      let(:allowed?) { false }

      it { is_expected.to be_disallowed(:read_issue_link) }
    end

    context 'when the associated issue can be read by the user' do
      let(:allowed?) { true }

      it { is_expected.to be_allowed(:read_issue_link) }
    end
  end
end
