# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupPushRule, 'GroupPushRule', :aggregate_failures, api: true, feature_category: :source_code_management do
  include ApiHelpers
  include AccessMatchersForRequest

  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:attributes) do
    {
      author_email_regex: '^[A-Za-z0-9.]+@gitlab.com$',
      commit_committer_check: true,
      commit_message_negative_regex: '[x+]',
      commit_message_regex: '[a-zA-Z]',
      deny_delete_tag: false,
      max_file_size: 100,
      member_check: false,
      prevent_secrets: true,
      reject_unsigned_commits: true
    }
  end

  shared_examples 'not found when feature is unavailable' do
    before do
      stub_licensed_features(push_rules: false)
    end

    it do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'allow access to api based on role' do
    context 'when admin', :enable_admin_mode do
      it { expect { subject }.to be_allowed_for(:admin) }
    end

    it { expect { subject }.to be_allowed_for(:owner).of(group) }

    it { expect { subject }.to be_denied_for(:developer).of(group) }
    it { expect { subject }.to be_denied_for(:reporter).of(group) }
    it { expect { subject }.to be_denied_for(:guest).of(group) }
    it { expect { subject }.to be_denied_for(:anonymous) }
  end

  shared_context 'licensed features available' do
    before do
      stub_licensed_features(push_rules: true,
                             commit_committer_check: true,
                             reject_unsigned_commits: true)
    end
  end

  describe 'GET /groups/:id/push_rule' do
    let_it_be(:group) { create(:group) }

    before_all do
      push_rule = create(:push_rule, **attributes)
      group.update!(push_rule: push_rule)
    end

    it_behaves_like 'GET request permissions for admin mode' do
      let(:path) { "/groups/#{group.id}/push_rule" }
      let(:failed_status_code) { :not_found }
    end

    context 'when unlicensed' do
      subject { get api("/groups/#{group.id}/push_rule", admin, admin_mode: true) }

      it_behaves_like 'not found when feature is unavailable'
    end

    context 'authorized user' do
      subject { get api("/groups/#{group.id}/push_rule", admin, admin_mode: true) }

      context 'when licensed' do
        include_context 'licensed features available'

        it 'returns attributes as expected' do
          subject

          expect(json_response).to eq(
            {
              "author_email_regex" => attributes[:author_email_regex],
              "branch_name_regex" => nil,
              "commit_committer_check" => true,
              "commit_message_negative_regex" => attributes[:commit_message_negative_regex],
              "commit_message_regex" => attributes[:commit_message_regex],
              "created_at" => group.reload.push_rule.created_at.iso8601(3),
              "deny_delete_tag" => false,
              "file_name_regex" => nil,
              "id" => group.push_rule.id,
              "max_file_size" => 100,
              "member_check" => false,
              "prevent_secrets" => true,
              "reject_unsigned_commits" => true
            }
          )
        end

        it 'matches response schema' do
          subject

          expect(response).to match_response_schema('entities/group_push_rules')
        end
      end

      context 'when reject_unsigned_commits is unavailable' do
        before do
          stub_licensed_features(reject_unsigned_commits: false)
        end

        it do
          subject

          expect(json_response).not_to have_key('reject_unsigned_commits')
        end
      end

      context 'when commit_committer_check is unavailable' do
        before do
          stub_licensed_features(commit_committer_check: false)
        end

        it do
          subject

          expect(json_response).not_to have_key('commit_committer_check')
        end
      end
    end

    context 'permissions' do
      subject(:get_push_rules) { get api("/groups/#{group.id}/push_rule", user) }

      it_behaves_like 'allow access to api based on role'
    end

    context 'when push rule does not exist' do
      let_it_be(:no_push_rule_group) { create(:group) }

      it 'returns not found' do
        get api("/groups/#{no_push_rule_group.id}/push_rule", admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /groups/:id/push_rule' do
    let_it_be(:group) { create(:group) }

    it_behaves_like 'POST request permissions for admin mode' do
      include_context 'licensed features available'

      let(:path) { "/groups/#{group.id}/push_rule" }
      let(:params) { attributes }
      let(:failed_status_code) { :not_found }
    end

    context 'when unlicensed' do
      subject { post api("/groups/#{group.id}/push_rule", admin, admin_mode: true), params: attributes }

      it_behaves_like 'not found when feature is unavailable'
    end

    context 'authorized user' do
      subject { post api("/groups/#{group.id}/push_rule", admin, admin_mode: true), params: attributes }

      context 'when licensed' do
        include_context 'licensed features available'

        it do
          subject

          expect(response).to have_gitlab_http_status(:created)
        end

        it do
          expect { subject }.to change { PushRule.count }.by(1)
        end

        it 'creates record with appropriate attributes' do
          subject

          push_rule = group.reload.push_rule

          expect(push_rule.author_email_regex).to eq(attributes[:author_email_regex])
          expect(push_rule.commit_committer_check).to eq(attributes[:commit_committer_check])
          expect(push_rule.commit_message_negative_regex).to eq(attributes[:commit_message_negative_regex])
          expect(push_rule.commit_message_regex).to eq(attributes[:commit_message_regex])
          expect(push_rule.deny_delete_tag).to eq(attributes[:deny_delete_tag])
          expect(push_rule.max_file_size).to eq(attributes[:max_file_size])
          expect(push_rule.member_check).to eq(attributes[:member_check])
          expect(push_rule.prevent_secrets).to eq(attributes[:prevent_secrets])
          expect(push_rule.reject_unsigned_commits).to eq(attributes[:reject_unsigned_commits])
        end

        context 'when push rule exists' do
          before do
            push_rule = create(:push_rule, **attributes)
            group.update!(push_rule: push_rule)
          end

          specify do
            subject

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response['message']).to eq('Group push rule exists, try updating')
          end
        end

        context 'permissions' do
          subject { post api("/groups/#{group.id}/push_rule", user), params: attributes }

          it_behaves_like 'allow access to api based on role'
        end

        context 'when no rule is specified' do
          specify do
            post api("/groups/#{group.id}/push_rule", admin, admin_mode: true), params: {}

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to include('at least one parameter must be provided')
          end
        end
      end

      context 'when reject_unsigned_commits is unavailable' do
        before do
          stub_licensed_features(reject_unsigned_commits: false)
          stub_licensed_features(push_rules: true, commit_committer_check: true)
        end

        it 'returns forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'and reject_unsigned_commits is not set' do
          it 'returns created' do
            post api("/groups/#{group.id}/push_rule", admin, admin_mode: true), params: attributes.except(:reject_unsigned_commits)

            expect(response).to have_gitlab_http_status(:created)
          end
        end
      end

      context 'when commit_committer_check is unavailable' do
        before do
          stub_licensed_features(commit_committer_check: false)
          stub_licensed_features(push_rules: true, reject_unsigned_commits: true)
        end

        it do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'and commit_committer_check is not set' do
          it 'returns created' do
            post api("/groups/#{group.id}/push_rule", admin, admin_mode: true), params: attributes.except(:commit_committer_check)

            expect(response).to have_gitlab_http_status(:created)
          end
        end
      end
    end
  end

  describe 'PUT /groups/:id/push_rule' do
    subject { put api("/groups/#{group.id}/push_rule", admin, admin_mode: true), params: attributes_for_update }

    let(:group) { create(:group) }

    let_it_be(:attributes_for_update) do
      {
        author_email_regex: '^[A-Za-z0-9.]+@disney.com$',
        reject_unsigned_commits: true,
        commit_committer_check: false
      }
    end

    before do
      push_rule = create(:push_rule, **attributes)
      group.update!(push_rule: push_rule)
    end

    it_behaves_like 'PUT request permissions for admin mode' do
      include_context 'licensed features available'

      let(:path) { "/groups/#{group.id}/push_rule" }
      let(:params) { attributes_for_update }
      let(:failed_status_code) { :not_found }
    end

    context 'when unlicensed' do
      it_behaves_like 'not found when feature is unavailable'
    end

    context 'authorized user' do
      context 'when licensed' do
        include_context 'licensed features available'

        it do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates attributes as expected' do
          expect { subject }.to change { group.reload.push_rule.author_email_regex }
                                  .from(attributes[:author_email_regex])
                                  .to(attributes_for_update[:author_email_regex])
        end

        context 'when push rule does not exist for group' do
          let_it_be(:group_without_push_rule) { create(:group) }

          it 'returns not found' do
            put api("/groups/#{group_without_push_rule.id}/push_rule", admin, admin_mode: true), params: attributes_for_update

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to include('Push Rule Not Found')
          end
        end

        context 'permissions' do
          subject { put api("/groups/#{group.id}/push_rule", user), params: attributes_for_update }

          it_behaves_like 'allow access to api based on role'
        end

        context 'when no rule is specified' do
          specify do
            put api("/groups/#{group.id}/push_rule", admin, admin_mode: true), params: {}

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to include('at least one parameter must be provided')
          end
        end
      end

      context 'when reject_unsigned_commits is unavailable' do
        before do
          stub_licensed_features(reject_unsigned_commits: false)
          stub_licensed_features(push_rules: true, commit_committer_check: true)
        end

        it 'returns forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'and reject_unsigned_commits is not set' do
          it 'returns status ok' do
            put api("/groups/#{group.id}/push_rule", admin, admin_mode: true), params: attributes_for_update.except(:reject_unsigned_commits)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'when commit_committer_check is unavailable' do
        before do
          stub_licensed_features(commit_committer_check: false)
          stub_licensed_features(push_rules: true, reject_unsigned_commits: true)
        end

        it do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'and commit_committer_check is not set' do
          it 'returns status ok' do
            put api("/groups/#{group.id}/push_rule", admin, admin_mode: true), params: attributes_for_update.except(:commit_committer_check)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end

  describe 'DELETE /groups/:id/push_rule' do
    let_it_be(:push_rule) { create(:push_rule, **attributes) }
    let_it_be(:group) { create(:group, push_rule: push_rule) }

    it_behaves_like 'DELETE request permissions for admin mode' do
      include_context 'licensed features available'

      let(:path) { "/groups/#{group.id}/push_rule" }
      let(:failed_status_code) { :not_found }
    end

    context 'authorized user' do
      context 'when licensed' do
        include_context 'licensed features available'

        context 'with group push rule' do
          specify do
            delete api("/groups/#{group.id}/push_rule", admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:no_content)
            expect(group.reload.push_rule).to be nil
          end
        end

        context 'when push rule does not exist' do
          it 'returns not found' do
            no_push_rule_group = create(:group)

            delete api("/groups/#{no_push_rule_group.id}/push_rule", admin)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when unlicensed' do
        subject { delete api("/groups/#{group.id}/push_rule", admin, admin_mode: true) }

        it_behaves_like 'not found when feature is unavailable'
      end
    end

    context 'permissions' do
      subject { delete api("/groups/#{group.id}/push_rule", user) }

      it_behaves_like 'allow access to api based on role'
    end
  end
end
