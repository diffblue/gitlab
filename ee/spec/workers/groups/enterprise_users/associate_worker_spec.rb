# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EnterpriseUsers::AssociateWorker, feature_category: :user_management do
  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:user) { create(:user) }
    let(:job_args) { [user.id] }
  end

  describe '#perform' do
    shared_examples 'does not do anything' do
      it 'does not do anything' do
        expect(Groups::EnterpriseUsers::AssociateService).not_to receive(:new)

        worker.perform(user_id)
      end
    end

    shared_examples 'executes Groups::EnterpriseUsers::AssociateService for root group and user' do
      it 'executes Groups::EnterpriseUsers::AssociateService for root group and user' do
        expect_next_instance_of(
          Groups::EnterpriseUsers::AssociateService,
          group: root_group, user: user
        ) do |associate_service|
          expect(associate_service).to receive(:execute).and_call_original
        end

        worker.perform(user_id)
      end
    end

    context 'when user does not exist for given user_id' do
      let(:user_id) { -1 }

      include_examples 'does not do anything'
    end

    context 'when user exist for given user_id' do
      let(:user) { create(:user, email: "user-email@#{email_domain}") }
      let(:user_id) { user.id }
      let(:email_domain) { 'example.GitLab.com' }

      context 'when there is no pages_domain record for user email domain' do
        include_examples 'does not do anything'
      end

      context 'when there is pages_domain record for user email domain' do
        let!(:pages_domain) { create(:pages_domain, domain: email_domain, project: project) }

        context 'when pages_domain does not belong to project' do
          let(:project) { nil }

          include_examples 'does not do anything'
        end

        context 'when pages_domain belongs to project' do
          context 'when project belongs to user' do
            let_it_be(:user_namespace) { create(:user).namespace }
            let_it_be(:project) { create(:project, namespace: user_namespace) }

            include_examples 'does not do anything'
          end
        end

        context 'when project belongs to root group' do
          let_it_be(:root_group) { create(:group) }
          let_it_be(:project) { create(:project, namespace: root_group) }

          include_examples 'executes Groups::EnterpriseUsers::AssociateService for root group and user'

          context 'when project is in subgroup' do
            let_it_be(:subgroup) { create(:group, parent: root_group) }
            let_it_be(:project) { create(:project, namespace: subgroup) }

            include_examples 'executes Groups::EnterpriseUsers::AssociateService for root group and user'
          end

          context 'when pages_domain is unverified' do
            before do
              pages_domain.update!(verified_at: nil)
            end

            include_examples 'does not do anything'
          end

          context 'when pages_domain differs from user email domain by the case' do
            before do
              pages_domain.update!(domain: email_domain.swapcase)
            end

            include_examples 'executes Groups::EnterpriseUsers::AssociateService for root group and user'
          end

          context 'when enterprise_users_automatic_claim FF is disabled' do
            before do
              stub_feature_flags(enterprise_users_automatic_claim: false)
            end

            include_examples 'does not do anything'
          end
        end
      end
    end
  end
end
