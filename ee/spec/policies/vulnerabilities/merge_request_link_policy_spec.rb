# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::MergeRequestLinkPolicy, feature_category: :vulnerability_management do
  let(:vulnerability_merge_request_link) do
    build(
      :vulnerabilities_merge_request_link,
      vulnerability: vulnerability,
      merge_request: merge_request
    )
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let_it_be(:vulnerability) { create(:vulnerability, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  subject { described_class.new(user, vulnerability_merge_request_link) }

  describe ':admin_vulnerability_merge_request_link' do
    before do
      stub_licensed_features(security_dashboard: true)

      project.add_developer(user)
    end

    context 'with missing vulnerability' do
      let_it_be(:vulnerability) { nil }
      let_it_be(:merge_request) { create(:merge_request) }

      it { is_expected.to be_disallowed(:admin_vulnerability_merge_request_link) }
    end

    context 'when merge_request and mere_request_link belong to the same project' do
      it { is_expected.to be_allowed(:admin_vulnerability_merge_request_link) }
    end

    context 'when merge_request and link don\'t belong to the same project' do
      let_it_be(:merge_request) { create(:merge_request) }

      it { is_expected.to be_allowed(:admin_vulnerability_merge_request_link) }
    end
  end

  describe ':read_merge_request_link' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(user, :read_merge_request, merge_request).and_return(allowed?)
    end

    context 'when the associated merge_request can not be read by the user' do
      let(:allowed?) { false }

      it { is_expected.to be_disallowed(:read_vulnerability_merge_request_link) }
    end

    context 'when the associated merge_request can be read by the user' do
      let(:allowed?) { true }

      it { is_expected.to be_allowed(:read_vulnerability_merge_request_link) }
    end
  end
end
