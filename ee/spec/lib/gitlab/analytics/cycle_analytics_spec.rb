# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:not_member_user) { create(:user) }
  let_it_be(:group) do
    create(:group).tap do |g|
      g.add_guest(guest)
      g.add_reporter(reporter)
      g.add_reporter(developer)
    end
  end

  let_it_be(:models) do
    {
      nil: nil,
      issue: create(:issue),
      project_namespace: create(:project, group: group).reload.project_namespace,
      public_project_namespace: create(:project, :public, group: group).reload.project_namespace,
      group: group
    }
  end

  let_it_be(:users) do
    {
      nil: nil,
      developer_user: developer,
      reporter_user: reporter,
      guest_user: guest,
      not_member: not_member_user
    }
  end

  describe '.licensed?' do
    where(:model, :enabled_license, :outcome) do
      :nil | nil | false
      :issue | nil | false
      :issue | :cycle_analytics_for_projects | false
      :issue | :cycle_analytics_for_groups | false
      :project_namespace | nil | false
      :project_namespace | :cycle_analytics_for_groups | false
      :project_namespace | :cycle_analytics_for_projects | true
      :public_project_namespace | nil | false
      :public_project_namespace | :cycle_analytics_for_groups | false
      :public_project_namespace | :cycle_analytics_for_projects | true
      :group | nil | false
      :group | :cycle_analytics_for_groups | true
      :group | :cycle_analytics_for_projects | false
    end

    with_them do
      subject { described_class.licensed?(models.fetch(model)) }

      before do
        stub_licensed_features(enabled_license => true) if enabled_license
      end

      it { is_expected.to eq(outcome) }
    end

    context 'when on SaaS', :saas do
      before do
        stub_licensed_features(cycle_analytics_for_projects: true)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when the parent is a group' do
        it 'succeeds' do
          group = create(:group_with_plan, plan: :ultimate_plan)
          project_namespace = create(:project, group: group).reload.project_namespace

          expect(described_class).to be_licensed(project_namespace)
        end
      end

      context 'when the parent is a user namespace' do
        it 'returns false' do
          namespace = create(:namespace_with_plan, plan: :ultimate_plan)
          project_namespace = create(:project, namespace: namespace).reload.project_namespace

          expect(described_class).not_to be_licensed(project_namespace)
        end
      end
    end
  end

  describe '.allowed?' do
    where(:model, :licensed, :user, :outcome) do
      :nil                      | true  | :developer_user | false
      :issue                    | true  | :developer_user | false
      :issue                    | true  | :reporter_user  | false
      :issue                    | true  | :guest_user     | false
      :issue                    | true  | :not_member     | false
      :project_namespace        | true  | :nil            | false
      :project_namespace        | true  | :reporter_user  | true
      :project_namespace        | true  | :guest_user     | false
      :project_namespace        | true  | :not_member     | false
      :public_project_namespace | true  | :nil            | false
      :public_project_namespace | true  | :reporter_user  | true
      :public_project_namespace | true  | :guest_user     | false
      :public_project_namespace | true  | :not_member     | false
      :project_namespace        | false | :nil            | false
      :project_namespace        | false | :reporter_user  | true
      :project_namespace        | false | :guest_user     | true
      :project_namespace        | false | :not_member     | false
      :public_project_namespace | false | :nil            | true
      :public_project_namespace | false | :reporter_user  | true
      :public_project_namespace | false | :guest_user     | true
      :public_project_namespace | false | :not_member     | true
      :group                    | true  | :nil            | false
      :group                    | true  | :reporter_user  | true
      :group                    | true  | :guest_user     | false
      :group                    | true  | :not_member     | false
    end

    with_them do
      before do
        stub_licensed_features(cycle_analytics_for_projects: licensed, cycle_analytics_for_groups: licensed)
      end

      subject { described_class.allowed?(users.fetch(user), models.fetch(model)) }

      it { is_expected.to eq(outcome) }
    end
  end

  describe '.subject_for_access_check' do
    subject(:subject_for_access_check) { described_class.subject_for_access_check(model) }

    context 'when Namespaces::ProjectNamespace is given' do
      let(:model) { models[:project_namespace] }

      it { is_expected.to eq(model.project) }
    end

    context 'when Group is given' do
      let(:model) { models[:group] }

      it { is_expected.to eq(model) }
    end

    context 'when something else is given' do
      let(:model) { models[:issue] }

      it 'raises error' do
        expect { subject_for_access_check }.to raise_error(/Unsupported subject given/)
      end
    end

    context 'when nil is given' do
      let(:model) { nil }

      it 'raises error' do
        expect { subject_for_access_check }.to raise_error(/Unsupported subject given/)
      end
    end
  end
end
