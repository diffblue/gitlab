# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::CreatorService, feature_category: :groups_and_projects do
  describe '.add_member' do
    context 'for onboarding concerns', :saas do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group_with_plan, :private, plan: :free_plan) }

      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        create(:group_member, source: group)
      end

      context 'when user qualifies for being in onboarding' do
        context 'when user has finished the welcome step' do
          before do
            user.update!(onboarding_in_progress: true, onboarding_step_url: '_url_')
          end

          it 'finishes onboarding' do
            expect do
              described_class.add_member(group, user, :owner)
            end.to change { user.reset.onboarding_in_progress }.from(true).to(false)
          end
        end

        context 'when user has not finished the welcome step' do
          before do
            user.update!(role: nil, onboarding_in_progress: true, onboarding_step_url: '_url_')
          end

          it 'does not finish onboarding' do
            expect do
              described_class.add_member(group, user, :owner)
            end.not_to change { user.reset.onboarding_in_progress }
          end
        end
      end

      context 'when user does not qualify for onboarding' do
        let(:check_namespace_plan) { false }

        context 'when user has finished the welcome step' do
          before do
            user.update!(onboarding_in_progress: true, onboarding_step_url: '_url_')
          end

          it 'does not finish onboarding' do
            expect do
              described_class.add_member(group, user, :owner)
            end.not_to change { user.reset.onboarding_in_progress }
          end
        end
      end
    end
  end
end
