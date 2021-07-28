# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupMembersController do
  include ExternalAuthorizationServiceHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group, :public) }
  let(:membership) { create(:group_member, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'PUT /groups/*group_id/-/group_members/:id' do
    context 'when group has email domain feature enabled' do
      let(:email) { 'test@gitlab.com' }
      let(:member_user) { create(:user, email: email) }
      let(:member) { group.add_guest(member_user) }

      before do
        stub_licensed_features(group_allowed_email_domains: true)
        create(:allowed_email_domain, group: group)
      end

      subject do
        put group_group_member_path(group_id: group, id: member), xhr: true, params: {
                                          group_member: {
                                            access_level: 50
                                          }
                                        }
      end

      context 'for a user with an email belonging to the allowed domain' do
        it 'returns error status' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'for a user with an un-verified email belonging to a domain different from the allowed domain' do
        let(:email) { 'test@gmail.com' }

        it 'returns error status' do
          subject

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          subject

          expect(json_response).to eq({ 'message' => "User email does not match the allowed domain of gitlab.com" })
        end
      end
    end
  end
end
