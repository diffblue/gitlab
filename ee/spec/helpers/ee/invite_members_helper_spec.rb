# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::InviteMembersHelper, feature_category: :onboarding do
  include Devise::Test::ControllerHelpers

  describe '#common_invite_group_modal_data' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group, :private, projects: [project]) }

    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
      stub_ee_application_setting(dashboard_limit: 5)
    end

    it 'has expected common attributes' do
      expect(helper.common_invite_group_modal_data(project, ProjectMember, 'true'))
        .to include({ free_user_cap_enabled: 'true', free_users_limit: 5 })
    end
  end

  describe '#common_invite_modal_dataset', :saas do
    let(:project) { build(:project) }

    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    context 'when applying the free user cap is not valid' do
      let!(:group) do
        create(:group_with_plan, :private, projects: [project], plan: :default_plan)
      end

      it 'does not include users limit notification data' do
        expect(helper.common_invite_modal_dataset(project)).not_to have_key(:users_limit_dataset)
      end
    end

    context 'when applying the free user cap is valid' do
      let!(:group) do
        create(:group_with_plan, :private, projects: [project], plan: :free_plan)
      end

      let(:expected_alert_data) do
        {
          'alert_variant' => expected_variant,
          'free_users_limit' => ::Namespaces::FreeUserCap.dashboard_limit,
          'remaining_seats' => expected_remaining_seats,
          'new_trial_registration_path' => new_trial_path(namespace_id: group.id),
          'purchase_path' => group_billings_path(project.root_ancestor),
          'members_path' => group_usage_quotas_path(project.root_ancestor)
        }
      end

      let(:users_limit_dataset) do
        Gitlab::Json.parse(helper.common_invite_modal_dataset(project)[:users_limit_dataset])
      end

      context 'with feature flag :preview_free_user_cap enabled' do
        let(:expected_remaining_seats) { 0 }

        before do
          stub_feature_flags(preview_free_user_cap: true)
          stub_feature_flags(free_user_cap: false)
        end

        context 'when notifying the free user cap limit' do
          context 'when not over limit' do
            let(:expected_variant) { nil }

            it 'includes correct users limit notification data' do
              expect(users_limit_dataset).to eq(expected_alert_data)
            end
          end

          context 'when over limit' do
            let_it_be(:user) { create(:user) }

            let(:expected_variant) { 'notification' }

            before do
              group.add_owner(user)
            end

            it 'includes correct users limit notification data' do
              expect(users_limit_dataset).to eq(expected_alert_data)
            end
          end
        end
      end

      context 'with feature flag :free_user_cap enabled' do
        before do
          stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: 2.days.ago)

          stub_feature_flags(preview_free_user_cap: false)
          stub_feature_flags(free_user_cap: true)
        end

        context 'when not close to or over the free user cap limit' do
          let(:expected_variant) { nil }
          let(:expected_remaining_seats) { 5 }

          before do
            stub_ee_application_setting(dashboard_limit: 5)
          end

          it 'includes correct users limit notification data' do
            expect(users_limit_dataset).to eq(expected_alert_data)
          end
        end

        context 'when close to the free user cap limit' do
          let(:expected_variant) { 'close' }
          let(:expected_remaining_seats) { 1 }

          before do
            stub_ee_application_setting(dashboard_limit: 1)
          end

          it 'includes correct users limit notification data' do
            expect(users_limit_dataset).to eq(expected_alert_data)
          end
        end

        context 'when at the free user cap limit' do
          let(:expected_variant) { 'reached' }
          let(:expected_remaining_seats) { 0 }

          it 'includes correct users limit notification data' do
            expect(users_limit_dataset).to eq(expected_alert_data)
          end
        end
      end
    end

    context 'with tasks_to_be_done' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:project) { create(:project) }
      let_it_be(:group) { create(:group, projects: [project]) }
      let_it_be(:developer) { create(:user, developer_projects: [project]) }

      subject(:output) { helper.common_invite_modal_dataset(source) }

      shared_examples_for 'including the tasks to be done attributes' do
        it 'includes the tasks to be done attributes when expected' do
          if expected?
            result = [
              { value: :code, text: 'Create/import code into a project (repository)' },
              { value: :ci, text: 'Set up CI/CD pipelines to build, test, deploy, and monitor code' },
              { value: :issues, text: 'Create/import issues (tickets) to collaborate on ideas and plan work' }
            ].to_json

            expect(output[:tasks_to_be_done_options]).to eq(result)
            expect(output[:projects]).to eq([{ id: project.id, title: project.title }].to_json)
            expect(output[:new_project_path])
              .to eq(source.is_a?(Project) ? '' : new_project_path(namespace_id: group.id))
          else
            expect(output[:tasks_to_be_done_options]).to be_nil
            expect(output[:projects]).to be_nil
            expect(output[:new_project_path]).to be_nil
          end
        end
      end
    end

    context 'when a namespace has an active trial' do
      let_it_be(:namespace) { create(:group, :private) }

      let(:active_trial_dataset) do
        Gitlab::Json.parse(helper.common_invite_modal_dataset(namespace)[:active_trial_dataset])
      end

      let(:expected_dataset) do
        {
          'free_users_limit' => ::Namespaces::FreeUserCap.dashboard_limit,
          'purchase_path' => group_billings_path(namespace.root_ancestor)
        }
      end

      before do
        create(:gitlab_subscription, :active_trial, namespace: namespace)
      end

      it 'includes correct active trial alert data' do
        expect(active_trial_dataset).to eq(expected_dataset)
      end
    end

    context 'when namespace does not have an active trial' do
      let_it_be(:namespace) { create(:group, :private) }

      before do
        create(:gitlab_subscription, :expired_trial, namespace: namespace)
      end

      it 'does not include users limit notification data' do
        expect(helper.common_invite_modal_dataset(namespace)).not_to have_key(:active_trial_dataset)
      end
    end
  end

  describe '#users_filter_data' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:saml_provider) { create(:saml_provider, group: group) }

    let!(:group2) { create(:group) }

    context 'when the group has enforced sso' do
      before do
        allow(group).to receive(:enforced_sso?).and_return(true)
      end

      context 'when there is a group with a saml provider' do
        it 'returns user filter data' do
          expected = { users_filter: 'saml_provider_id', filter_id: saml_provider.id }

          expect(helper.users_filter_data(group)).to eq expected
        end
      end

      context 'when there is a group without a saml provider' do
        it 'does not return user filter data' do
          expect(helper.users_filter_data(group2)).to eq({})
        end
      end
    end

    context 'when group has enforced sso disabled' do
      before do
        allow(group).to receive(:enforced_sso?).and_return(false)
      end

      context 'when there is a group with a saml provider' do
        it 'does not return user filter data' do
          expect(helper.users_filter_data(group)).to eq({})
        end
      end

      context 'when there is a group without a saml provider' do
        it 'does not return user filter data' do
          expect(helper.users_filter_data(group2)).to eq({})
        end
      end
    end
  end
end
