# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialStatusWidgetHelper, :saas do
  describe 'data attributes for mounting Vue components', :freeze_time do
    let(:trial_length) { 30 } # days
    let(:trial_days_remaining) { 18 }
    let(:trial_end_date) { Date.current.advance(days: trial_days_remaining) }
    let(:trial_start_date) { Date.current.advance(days: trial_days_remaining - trial_length) }
    let(:trial_percentage_complete) { (trial_length - trial_days_remaining) * 100 / trial_length }

    let_it_be(:group) { create(:group) }

    let(:shared_expected_attrs) do
      {
        container_id: 'trial-status-sidebar-widget',
        days_remaining: trial_days_remaining,
        plan_name: 'Ultimate',
        plans_href: group_billings_path(group)
      }
    end

    before do
      build(:gitlab_subscription, :active_trial,
        namespace: group,
        trial_starts_on: trial_start_date,
        trial_ends_on: trial_end_date
      )
      stub_experiments(group_contact_sales: :control)
      stub_experiments(forcibly_show_trial_status_popover: :candidate)
      allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService, plan: :free) do |instance|
        allow(instance).to receive(:execute).and_return([
          { 'code' => 'ultimate', 'id' => 'ultimate-plan-id' }
        ])
      end
    end

    describe '#trial_status_popover_data_attrs' do
      using RSpec::Parameterized::TableSyntax

      d14_callout_id = described_class::D14_CALLOUT_ID
      d3_callout_id = described_class::D3_CALLOUT_ID

      let(:user_callouts_feature_id) { nil }
      let(:dismissed_callout) { true }

      let_it_be(:user) { create(:user) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(user).to receive(:dismissed_callout?).with(feature_name: user_callouts_feature_id).and_return(dismissed_callout)
      end

      subject(:data_attrs) { helper.trial_status_popover_data_attrs(group) }

      shared_examples 'has correct data attributes' do
        it 'returns the needed data attributes for mounting the popover Vue component' do
          expect(data_attrs).to match(
            shared_expected_attrs.merge(
              group_name: group.name,
              purchase_href: new_subscriptions_path(namespace_id: group.id, plan_id: 'ultimate-plan-id'),
              target_id: shared_expected_attrs[:container_id],
              start_initially_shown: start_initially_shown,
              trial_end_date: trial_end_date,
              user_callouts_path: callouts_path,
              user_callouts_feature_id: user_callouts_feature_id
            )
          )
        end
      end

      where(:trial_days_remaining, :user_callouts_feature_id, :dismissed_callout, :start_initially_shown) do
        # days| callout ID      | dismissed?  | shown?
        30    | nil             | false       | false
        20    | nil             | false       | false
        15    | nil             | false       | false
        14    | d14_callout_id  | false       | true
        14    | d14_callout_id  | true        | false
        10    | d14_callout_id  | false       | true
        10    | d14_callout_id  | true        | false
        7     | d14_callout_id  | false       | true
        7     | d14_callout_id  | true        | false
        # days| callout ID      | dismissed?  | shown?
        6     | nil             | false       | false
        4     | nil             | false       | false
        3     | d3_callout_id   | false       | true
        3     | d3_callout_id   | true        | false
        1     | d3_callout_id   | false       | true
        1     | d3_callout_id   | true        | false
        0     | d3_callout_id   | false       | true
        0     | d3_callout_id   | true        | false
        -1    | nil             | false       | false
      end

      with_them { include_examples 'has correct data attributes' }

      context 'when not part of the experiment' do
        before do
          stub_experiments(forcibly_show_trial_status_popover: :control)
        end

        where(:trial_days_remaining, :user_callouts_feature_id, :dismissed_callout, :start_initially_shown) do
          # days| callout ID      | dismissed?  | shown?
          30    | nil             | false       | false
          20    | nil             | false       | false
          15    | nil             | false       | false
          14    | d14_callout_id  | false       | false
          14    | d14_callout_id  | true        | false
          10    | d14_callout_id  | false       | false
          10    | d14_callout_id  | true        | false
          7     | d14_callout_id  | false       | false
          7     | d14_callout_id  | true        | false
          # days| callout ID      | dismissed?  | shown?
          6     | nil             | false       | false
          4     | nil             | false       | false
          3     | d3_callout_id   | false       | false
          3     | d3_callout_id   | true        | false
          1     | d3_callout_id   | false       | false
          1     | d3_callout_id   | true        | false
          0     | d3_callout_id   | false       | false
          0     | d3_callout_id   | true        | false
          -1    | nil             | false       | false
        end

        with_them { include_examples 'has correct data attributes' }
      end

      it 'records the experiment subject' do
        expect { data_attrs }.to change { ExperimentSubject.count }
      end

      context 'when group_contact_sales is enabled' do
        before do
          stub_experiments(group_contact_sales: :candidate)
        end

        it 'returns the needed data attributes for mounting the popover Vue component' do
          expect(data_attrs).to match(
            shared_expected_attrs.merge(
              namespace_id: group.id,
              user_name: user.username,
              first_name: user.first_name,
              last_name: user.last_name,
              company_name: user.organization,
              glm_content: 'trial-status-show-group',
              group_name: group.name,
              purchase_href: new_subscriptions_path(namespace_id: group.id, plan_id: 'ultimate-plan-id'),
              target_id: shared_expected_attrs[:container_id],
              start_initially_shown: false,
              trial_end_date: trial_end_date,
              user_callouts_path: callouts_path,
              user_callouts_feature_id: user_callouts_feature_id
            )
          )
        end
      end
    end

    describe '#trial_status_widget_data_attrs' do
      before do
        allow(helper).to receive(:image_path).and_return('/image-path/for-file.svg')
      end

      subject(:data_attrs) { helper.trial_status_widget_data_attrs(group) }

      it 'returns the needed data attributes for mounting the widget Vue component' do
        expect(data_attrs).to match(
          shared_expected_attrs.merge(
            nav_icon_image_path: '/image-path/for-file.svg',
            percentage_complete: trial_percentage_complete
          )
        )
      end
    end
  end
end
