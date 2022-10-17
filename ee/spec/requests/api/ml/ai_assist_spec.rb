# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::AiAssist do
  let_it_be(:user) { create(:user) }
  let_it_be(:group_user) { create(:user) }
  let(:current_user) { nil }

  let_it_be(:allowed_group) do
    group = create(:group)
    group.add_owner(group_user)
    group
  end

  describe 'GET /ml/aiassist user_is_allowed' do
    before do
      stub_licensed_features(ai_assist: false)
      stub_feature_flags(ai_assist_flag: false)
    end

    subject { get api("/ml/aiassist", current_user) }

    context "when unauthorized" do
      it "returns forbidden error" do
        subject
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authorized but not ultimate, not in group, no FF" do
      let(:current_user) { user }

      it "returns forbidden error" do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when authorized but not ultimate, in group, no FF" do
      let(:current_user) { group_user }

      it "returns forbidden error" do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when authorized and ultimate, not in group but no FF" do
      let(:current_user) { user }

      it "returns forbidden error" do
        stub_licensed_features(ai_assist: true)
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when authorized and ultimate, in group but no FF" do
      let(:current_user) { group_user }

      it "returns forbidden error" do
        stub_licensed_features(ai_assist: true)
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when authorized and ultimate, not in group and FF" do
      let(:current_user) { user }

      it "returns forbidden error" do
        stub_licensed_features(ai_assist: true)
        stub_feature_flags(ai_assist_flag: allowed_group)
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when authorized and ultimate, in group and FF" do
      let(:current_user) { group_user }

      it "returns forbidden error" do
        stub_licensed_features(ai_assist: true)
        stub_feature_flags(ai_assist_flag: allowed_group)
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response["user_is_allowed"]).to eq true
      end
    end
  end
end
