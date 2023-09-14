# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::CreateService, feature_category: :user_management do
  shared_examples 'service account creation failure' do
    it 'produces an error', :aggregate_failures do
      result = service.execute

      expect(result.status).to eq(:error)
      expect(result.message).to eq(
        s_('ServiceAccount|User does not have permission to create a service account in this namespace.')
      )
    end
  end

  let_it_be(:group) { create(:group) }

  subject(:service) { described_class.new(current_user, { namespace_id: group.id }) }

  context 'when current user is an owner' do
    let_it_be(:current_user) { create(:user).tap { |user| group.add_owner(user) } }

    it_behaves_like 'service account creation failure'

    context 'when the feature is available' do
      before do
        stub_licensed_features(service_accounts: true)
      end

      context 'when self managed' do
        before do
          allow(License).to receive(:current).and_return(license)
        end

        context 'when subscription is of starter plan' do
          let(:license) { create(:license, plan: License::STARTER_PLAN) }

          it 'raises error' do
            result = service.execute

            expect(result.status).to eq(:error)
            expect(result.message).to include('No more seats are available to create Service Account User')
          end
        end

        context 'when subscription is ultimate tier' do
          let(:license) { create(:license, plan: License::ULTIMATE_PLAN) }

          it_behaves_like 'service account creation success' do
            let(:username_prefix) { "service_account_group_#{group.id}" }
          end

          it 'sets provisioned by group' do
            result = service.execute
            expect(result.payload.provisioned_by_group_id).to eq(group.id)
          end

          context 'when the group is invalid' do
            subject(:service) { described_class.new(current_user, { namespace_id: non_existing_record_id }) }

            it_behaves_like 'service account creation failure'
          end
        end

        context 'when subscription is of premium tier' do
          let(:license) { create(:license, plan: License::PREMIUM_PLAN) }
          let_it_be(:service_account1) { create(:user, :service_account, provisioned_by_group_id: group.id) }
          let_it_be(:service_account2) { create(:user, :service_account, provisioned_by_group_id: group.id) }

          context 'when premium seats are not available' do
            before do
              allow(license).to receive(:restricted_user_count).and_return(1)
            end

            it 'raises error' do
              result = service.execute

              expect(result.status).to eq(:error)
              expect(result.message).to include('No more seats are available to create Service Account User')
            end
          end

          context 'when premium seats are available' do
            before do
              allow(license).to receive(:restricted_user_count).and_return(User.service_account.count + 2)
            end

            it_behaves_like 'service account creation success' do
              let(:username_prefix) { "service_account_group_#{group.id}" }
            end

            it 'sets provisioned by group' do
              result = service.execute

              expect(result.payload.provisioned_by_group_id).to eq(group.id)
            end

            context 'when the group is invalid' do
              subject(:service) { described_class.new(current_user, { namespace_id: non_existing_record_id }) }

              it_behaves_like 'service account creation failure'
            end
          end
        end
      end

      context 'when saas', :saas do
        before do
          create(:gitlab_subscription, namespace: group, hosted_plan: hosted_plan)
          stub_application_setting(check_namespace_plan: true)
        end

        context 'when subscription is of free plan' do
          let(:hosted_plan) { create(:free_plan) }

          it_behaves_like 'service account creation failure'
        end

        context 'when subscription is ultimate tier' do
          let(:hosted_plan) { create(:ultimate_plan) }

          it_behaves_like 'service account creation success' do
            let(:username_prefix) { "service_account_group_#{group.id}" }
          end

          it 'sets provisioned by group' do
            result = service.execute
            expect(result.payload.provisioned_by_group_id).to eq(group.id)
          end

          context 'when the group is invalid' do
            subject(:service) { described_class.new(current_user, { namespace_id: non_existing_record_id }) }

            it_behaves_like 'service account creation failure'
          end
        end

        context 'when subscription is of premium tier' do
          let_it_be(:hosted_plan) { create(:premium_plan) }
          let_it_be(:service_account1) { create(:user, :service_account, provisioned_by_group_id: group.id) }
          let_it_be(:service_account2) { create(:user, :service_account, provisioned_by_group_id: group.id) }

          context 'when premium seats are not available' do
            before do
              group.gitlab_subscription.update!(seats: 1)
            end

            it 'raises error' do
              result = service.execute

              expect(result.status).to eq(:error)
              expect(result.message).to include(
                s_('ServiceAccount|No more seats are available to create Service Account User')
              )
            end
          end

          context 'when premium seats are available' do
            before do
              group.gitlab_subscription.update!(seats: 4)
            end

            it_behaves_like 'service account creation success' do
              let(:username_prefix) { "service_account_group_#{group.id}" }
            end

            it 'sets provisioned by group' do
              result = service.execute

              expect(result.payload.provisioned_by_group_id).to eq(group.id)
            end

            context 'when the group is invalid' do
              subject(:service) { described_class.new(current_user, { namespace_id: non_existing_record_id }) }

              it_behaves_like 'service account creation failure'
            end
          end
        end
      end
    end
  end

  context 'when the current user is not an owner', :saas do
    let_it_be(:current_user) { create(:user).tap { |user| group.add_maintainer(user) } }
    let(:hosted_plan) { create(:ultimate_plan) }

    before do
      stub_licensed_features(service_accounts: true)
      create(:gitlab_subscription, namespace: group, hosted_plan: hosted_plan)
    end

    it_behaves_like 'service account creation failure'
  end
end
