# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Push Rules', :js, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:push_rule) { create(:push_rule_without_project) }
  let_it_be(:group) { create(:group, push_rule: push_rule) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  push_rules_with_titles = {
    reject_unsigned_commits: 'Reject unsigned commits',
    commit_committer_check: 'Reject unverified users'
  }

  push_rules_with_titles.each do |rule_attr, title|
    describe "#{rule_attr} rule" do
      context 'unlicensed' do
        before do
          stub_licensed_features(rule_attr => false)
        end

        it 'does not render the setting checkbox' do
          visit group_settings_repository_path(group, anchor: 'js-push-rules')

          expect(page).not_to have_content(title)
        end
      end

      context 'licensed' do
        before do
          stub_licensed_features(rule_attr => true)
        end

        it 'renders the setting checkbox' do
          visit group_settings_repository_path(group, anchor: 'js-push-rules')

          expect(page).to have_content(title)
        end

        describe 'with GL.com plans', :saas do
          before do
            stub_application_setting(check_namespace_plan: true)
          end

          context 'when disabled' do
            it 'does not render the setting checkbox' do
              create(:gitlab_subscription, :bronze, namespace: group)

              visit group_settings_repository_path(group, anchor: 'js-push-rules')

              expect(page).not_to have_content(title)
            end
          end

          context 'when enabled' do
            it 'renders the setting checkbox' do
              create(:gitlab_subscription, :ultimate, namespace: group)

              visit group_settings_repository_path(group, anchor: 'js-push-rules')

              expect(page).to have_content(title)
            end
          end
        end
      end
    end
  end
end
