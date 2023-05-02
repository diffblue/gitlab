# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::FetchPolicyApproversService, feature_category: :security_policy_management do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :public, namespace: group) }
    let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }
    let_it_be(:user) { create(:user) }

    let(:container) { project }
    let(:policy) { build(:scan_result_policy, actions: [action]) }

    subject(:service) do
      described_class.new(policy: policy, current_user: user, container: container)
    end

    before do
      group.add_member(user, :owner)
    end

    context 'with group outside of the scope' do
      let(:unrelated_group) { create(:group, :private) }
      let(:action) { { type: "require_approval", approvals_required: 1, group_approvers_ids: [unrelated_group.id, group.id] } }

      it 'does not return the unrelated group' do
        response = service.execute

        expect(response[:groups]).to contain_exactly(group)
      end
    end

    context 'with user approver' do
      let(:action) { { type: "require_approval", approvals_required: 1, user_approvers: [user.username] } }

      it 'returns user approvers' do
        response = service.execute

        expect(response[:status]).to eq(:success)
        expect(response[:users]).to match_array([user])
        expect(response[:groups]).to be_empty
      end

      context 'with container of a group type' do
        let(:container) { group }

        it 'returns user approvers' do
          response = service.execute

          expect(response[:status]).to eq(:success)
          expect(response[:users]).to match_array([user])
          expect(response[:groups]).to be_empty
        end

        context 'with user approvers inherited from parent group' do
          let(:action) { { type: "require_approval", approvals_required: 1, user_approvers: [user.username] } }

          let_it_be(:child) { create(:group, parent: group) }
          let(:container) { child }

          it 'returns user approvers' do
            response = service.execute

            expect(response[:status]).to eq(:success)
            expect(response[:users]).to match_array([user])
            expect(response[:groups]).to be_empty
          end
        end
      end

      context 'with container of any other type' do
        let(:container) { create(:namespace) }

        it 'does returns any user approvers' do
          response = service.execute

          expect(response[:status]).to eq(:success)
          expect(response[:users]).to be_empty
          expect(response[:groups]).to be_empty
        end
      end
    end

    context 'with group approver' do
      let(:action) { { type: "require_approval", approvals_required: 1, group_approvers_ids: [group.id] } }

      it 'returns group approvers' do
        response = service.execute

        expect(response[:status]).to eq(:success)
        expect(response[:groups]).to match_array([group])
        expect(response[:users]).to be_empty
      end

      context 'when groups with same name exist in and outside of container' do
        let_it_be(:other_container) { create(:group) }
        let_it_be(:other_group) { create(:group, name: group.name, parent: other_container) }

        let(:action) { { type: "require_approval", approvals_required: 1, group_approvers: [group.name] } }

        subject { service.execute[:groups] }

        context 'with security_policy_global_group_approvers_enabled setting disabled' do
          before do
            stub_ee_application_setting(security_policy_global_group_approvers_enabled: false)
          end

          it 'excludes groups outside the container' do
            expect(subject).not_to include(other_group)
          end
        end

        context 'with security_policy_global_group_approvers_enabled setting enabled' do
          before do
            stub_ee_application_setting(security_policy_global_group_approvers_enabled: true)
          end

          it 'includes groups outside the container' do
            expect(subject).to include(other_group)
          end
        end
      end
    end

    context 'with role approver' do
      let(:action) { { type: "require_approval", approvals_required: 1, role_approvers: roles } }

      context 'when role_approvers in policy is empty' do
        let(:roles) { [] }

        it 'returns empty roles' do
          response = service.execute

          expect(response[:status]).to eq(:success)
          expect(response[:roles]).to be_empty
          expect(response[:users]).to be_empty
        end
      end

      context 'when role_approvers in policy is not empty' do
        let(:roles) { %w[maintainer developer] }

        it 'returns role approvers' do
          response = service.execute

          expect(response[:status]).to eq(:success)
          expect(response[:roles]).to match_array(roles)
          expect(response[:users]).to be_empty
        end

        context 'and contains GUEST or REPORTER' do
          let(:roles) { %w[maintainer developer guest reporter] }

          it 'returns role approvers without guest and reporters' do
            response = service.execute

            expect(response[:status]).to eq(:success)
            expect(response[:roles]).to match_array(%w[maintainer developer])
            expect(response[:users]).to be_empty
          end
        end
      end
    end

    context 'with both user and group approvers' do
      let(:action) { { type: "require_approval", approvals_required: 1, group_approvers: [group.path], user_approvers_ids: [user.id] } }

      it 'returns all approvers' do
        response = service.execute

        expect(response[:status]).to eq(:success)
        expect(response[:users]).to match_array([user])
        expect(response[:groups]).to match_array([group])
      end
    end

    context 'with policy equals to nil' do
      let(:policy) { nil }

      it 'returns no approver' do
        response = service.execute

        expect(response[:status]).to eq(:success)
        expect(response[:users]).to be_empty
        expect(response[:groups]).to be_empty
      end
    end

    context 'with action equals to nil' do
      let(:action) { nil }

      it 'returns no approver' do
        response = service.execute

        expect(response[:status]).to eq(:success)
        expect(response[:users]).to be_empty
        expect(response[:groups]).to be_empty
      end
    end

    context 'with action of an unknown type' do
      let(:action) { { type: "random_type", approvals_required: 1, group_approvers_ids: [group.id] } }

      it 'returns no approver' do
        response = service.execute

        expect(response[:status]).to eq(:success)
        expect(response[:users]).to be_empty
        expect(response[:groups]).to be_empty
      end
    end

    context 'with more users than the limit' do
      using RSpec::Parameterized::TableSyntax

      let(:user_ids) { [user.id] }
      let(:user_names) { [user.username] }

      where(:ids_multiplier, :names_multiplier, :ids_expected, :names_expected) do
        150 | 150 | 150 | 150
        300 | 300 | 0   | 300
        300 | 200 | 100 | 200
        600 | 600 | 0   | 300
      end

      with_them do
        let(:user_ids_multiplied) { user_ids * ids_multiplier }
        let(:user_name_multiplied) { user_names * names_multiplier }
        let(:user_ids_expected) { user_ids * ids_expected }
        let(:user_name_expected) { user_names * names_expected }
        let(:action) { { type: "require_approval", approvals_required: 1, user_approvers: user_name_multiplied, user_approvers_ids: user_ids_multiplied } }

        it 'considers only the first within the limit' do
          expect(project).to receive_message_chain(:team, :users, :by_ids_or_usernames).with(user_ids_expected, user_name_expected)

          service.execute

          expect((user_ids_expected + user_name_expected).count).not_to be > Security::ScanResultPolicy::APPROVERS_LIMIT
        end
      end
    end

    context 'with more groups than the limit' do
      let_it_be(:over_limit) { Security::ScanResultPolicy::APPROVERS_LIMIT + 1 }
      let_it_be(:groups) { create_list(:group, over_limit) }
      let_it_be(:groups_ids) { groups.pluck(:id) }
      let_it_be(:groups_paths) { groups.pluck(:path) }

      let(:action) { { type: "require_approval", approvals_required: 1, group_approvers: groups_paths, group_approvers_ids: groups_ids } }

      it 'considers only the first within the limit' do
        response = service.execute

        expect(response[:status]).to eq(:success)
        expect(response[:users]).to be_empty
        expect(response[:groups].count).not_to be > Security::ScanResultPolicy::APPROVERS_LIMIT
      end
    end
  end
end
