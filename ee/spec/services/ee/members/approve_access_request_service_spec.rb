# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ApproveAccessRequestService, feature_category: :subgroups do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:access_requester_user) { create(:user) }
  let(:access_requester) { source.requesters.find_by!(user_id: access_requester_user.id) }
  let(:opts) { {} }
  let(:params) { {} }
  let(:custom_access_level) { Gitlab::Access::MAINTAINER }

  shared_examples "auditor with context" do
    it "creates audit event with name" do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(name: "member_created")
      ).and_call_original

      described_class.new(current_user, params).execute(access_requester, **opts)
    end
  end

  context "with auditing" do
    context "for project access" do
      let(:source) { project }

      before do
        project.add_maintainer(current_user)
        project.request_access(access_requester_user)
      end

      it_behaves_like "auditor with context"
    end

    context "for group access" do
      let(:source) { group }

      before do
        group.add_owner(current_user)
        group.request_access(access_requester_user)
      end

      it_behaves_like "auditor with context"
    end
  end
end
