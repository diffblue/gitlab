# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Groups::PushRulesController, feature_category: :source_code_management do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  describe '#update' do
    def do_update
      patch :update, params: { group_id: group, push_rule: { prevent_secrets: true } }
    end

    before do
      sign_in(user)
    end

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)

        group.add_maintainer(user)
      end

      it 'returns 404 status' do
        do_update

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'push rules licensed' do
      before do
        stub_licensed_features(push_rules: true)
      end

      shared_examples 'updateable setting' do |rule_attr, new_value|
        it 'updates the setting' do
          patch :update, params: { group_id: group, push_rule: { rule_attr => new_value } }

          expect(group.reload.push_rule.public_send(rule_attr)).to eq(new_value)
        end
      end

      shared_examples 'not updateable setting' do |rule_attr, new_value|
        it 'does not update the setting' do
          expect do
            patch :update, params: { group_id: group, push_rule: { rule_attr => new_value } }
          end.not_to change { group.reload.push_rule.public_send(rule_attr) }
        end
      end

      shared_examples 'an updatable setting with global default' do |rule_attr|
        context "when #{rule_attr} not specified on global level" do
          before do
            stub_licensed_features(rule_attr => true)
          end

          it_behaves_like 'updateable setting', rule_attr, true
        end

        context "when global setting #{rule_attr} is enabled" do
          before do
            stub_licensed_features(rule_attr => true)
            create(:push_rule_sample, rule_attr => true)
          end

          it_behaves_like 'updateable setting', rule_attr, true
        end
      end

      shared_examples 'a not updatable setting with global default' do |rule_attr|
        context "when #{rule_attr} is disabled" do
          before do
            stub_licensed_features(rule_attr => false)
          end

          it_behaves_like 'not updateable setting', rule_attr, true
        end

        context "when global setting #{rule_attr} is enabled" do
          before do
            stub_licensed_features(rule_attr => true)
            create(:push_rule_sample, rule_attr => true)
          end

          it_behaves_like 'not updateable setting', rule_attr, true
        end
      end

      PushRule::SETTINGS_WITH_GLOBAL_DEFAULT.each do |rule_attr|
        context "Updating #{rule_attr} rule" do
          let(:push_rule_for_group) { create(:push_rule, rule_attr => false) }

          before do
            group.update!(push_rule_id: push_rule_for_group.id)
          end

          context 'as an admin' do
            let(:user) { create(:admin) }

            context 'when admin mode enabled', :enable_admin_mode do
              it_behaves_like 'an updatable setting with global default', rule_attr, updates: true
            end

            context 'when admin mode disabled' do
              it_behaves_like 'a not updatable setting with global default', rule_attr, updates: true
            end
          end

          context 'as a maintainer user' do
            before do
              group.add_maintainer(user)
            end

            it 'updates the push rule' do
              do_update

              expect(response).to have_gitlab_http_status(:found)
              expect(group.reload.push_rule.prevent_secrets).to be_truthy
            end

            context "when global setting #{rule_attr} is disabled" do
              before do
                stub_licensed_features(rule_attr => false)
                create(:push_rule_sample, rule_attr => true)
              end

              it_behaves_like 'updateable setting', rule_attr, true
            end

            context "when global setting #{rule_attr} is enabled" do
              before do
                stub_licensed_features(rule_attr => true)
                create(:push_rule_sample, rule_attr => true)
              end

              it_behaves_like 'not updateable setting', rule_attr, true
            end
          end

          context 'as a developer user' do
            before do
              group.add_developer(user)
            end

            it_behaves_like 'a not updatable setting with global default', rule_attr
          end
        end
      end

      shared_examples 'updates push rule commit_committer_name_check of group' do |result|
        it 'matches the given result' do
          patch :update, params: { group_id: group, push_rule: { 'commit_committer_name_check' => true } }

          expect(group.reload.push_rule.commit_committer_name_check).to eq(result)
        end
      end

      context "Updating commit_committer_name_check rule" do
        let(:push_rule_for_group) { create(:push_rule) }

        before do
          group.update!(push_rule_id: push_rule_for_group.id)
        end

        context 'when commit_committer_name_check is disabled' do
          before do
            stub_licensed_features(commit_committer_name_check: false)
          end

          context 'as an admin' do
            let(:user) { create(:admin) }

            context 'when admin mode enabled', :enable_admin_mode do
              it_behaves_like 'updates push rule commit_committer_name_check of group', false
            end
          end

          context 'as a maintainer user' do
            before do
              group.add_maintainer(user)
            end

            it_behaves_like 'updates push rule commit_committer_name_check of group', false
          end

          context 'as a developer user' do
            before do
              group.add_developer(user)
            end

            it_behaves_like 'updates push rule commit_committer_name_check of group', false
          end
        end

        context 'when commit_committer_name_check is enabled' do
          before do
            stub_licensed_features(commit_committer_name_check: true)
          end

          context 'as an admin' do
            let(:user) { create(:admin) }

            context 'when admin mode enabled', :enable_admin_mode do
              it_behaves_like 'updates push rule commit_committer_name_check of group', true
            end
          end

          context 'as a maintainer user' do
            before do
              group.add_maintainer(user)
            end

            it_behaves_like 'updates push rule commit_committer_name_check of group', true
          end

          context 'as a developer user' do
            before do
              group.add_developer(user)
            end

            it_behaves_like 'updates push rule commit_committer_name_check of group', false
          end
        end
      end
    end

    context 'when user role is lower than maintainer' do
      before do
        sign_in(user)
        group.add_developer(user)
      end

      context 'push rules unlicensed' do
        before do
          stub_licensed_features(push_rules: false)
        end

        it 'returns 404 status' do
          do_update

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'push rules licensed' do
        before do
          stub_licensed_features(push_rules: true)
        end

        it 'returns 404 status' do
          do_update

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
