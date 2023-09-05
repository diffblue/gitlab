# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::StandardContext, feature_category: :service_ping do
  let(:snowplow_context) { subject.to_context }

  describe '#to_context' do
    context 'on .com' do
      let(:user_id) { 1 }

      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      subject do
        described_class.new(user_id: user_id)
      end

      context 'when user_id is nil' do
        let(:user_id) { nil }

        it 'sets is_gitlab_team_member to nil' do
          expect(snowplow_context.to_json[:data][:is_gitlab_team_member]).to eq(nil)
        end
      end

      context 'with GitLab team member' do
        before do
          allow(Gitlab::Com).to receive(:gitlab_com_group_member?).with(user_id).and_return(true)
        end

        it 'sets is_gitlab_team_member to true' do
          expect(snowplow_context.to_json[:data][:is_gitlab_team_member]).to eq(true)
        end
      end

      context 'with non GitLab team member' do
        before do
          allow(Gitlab::Com).to receive(:gitlab_com_group_member?).with(user_id).and_return(false)
        end

        it 'sets is_gitlab_team_member to false' do
          expect(snowplow_context.to_json[:data][:is_gitlab_team_member]).to eq(false)
        end
      end
    end
  end
end
