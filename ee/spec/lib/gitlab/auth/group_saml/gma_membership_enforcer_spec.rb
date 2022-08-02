# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::GmaMembershipEnforcer do
  include ProjectForksHelper

  let(:group) { create(:group_with_managed_accounts, :private) }
  let(:project) { create(:project, namespace: group) }
  let(:managed_user) { create(:user, :group_managed, managing_group: group) }
  let(:managed_user_for_project) { create(:user, :group_managed, managing_group: group) }

  subject { described_class.new(project) }

  before do
    stub_licensed_features(group_saml: true)
  end

  it 'allows adding a project bot to project' do
    project_bot = create(:user, :project_bot)

    expect(subject.can_add_user?(project_bot)).to be_truthy
  end

  context 'when user is group-managed' do
    it 'allows adding user to project' do
      expect(subject.can_add_user?(managed_user)).to be_truthy
    end
  end

  context 'when user is not group-managed' do
    it 'does not allow adding user to project' do
      user = create(:user)

      expect(subject.can_add_user?(user)).to be_falsey
    end
  end

  context 'when the project is forked' do
    before do
      project.add_developer(managed_user_for_project)
    end

    subject { described_class.new(fork_project(project, managed_user_for_project)) }

    context 'when user is group-managed' do
      it 'allows adding user to project' do
        expect(subject.can_add_user?(managed_user)).to be_truthy
      end
    end

    context 'when user is not group-managed' do
      it 'does not allow adding user to project' do
        expect(subject.can_add_user?(create(:user))).to be_falsey
      end
    end

    context 'from deleted project' do
      let!(:forked_project) { fork_project(project, managed_user_for_project) }

      before do
        project.delete
      end

      context 'when user is group-managed' do
        it 'allows adding user to project' do
          subject = described_class.new(forked_project)
          expect(subject.can_add_user?(managed_user)).to be_truthy
        end
      end

      context 'when user is not group-managed' do
        it 'does not allow adding user to project' do
          subject = described_class.new(forked_project)
          expect(subject.can_add_user?(create(:user))).to be_truthy
        end
      end
    end
  end

  context 'when project is forked from namespace to group' do
    let(:project) { create(:project) }
    let(:forked_project) { create(:project, namespace: group) }

    subject { described_class.new(forked_project) }

    before do
      project.add_developer(managed_user_for_project)
      fork_project(project, managed_user_for_project, namespace: group, target_project: forked_project)
    end

    context 'when user is group-managed' do
      it 'allows adding user to project' do
        expect(subject.can_add_user?(managed_user)).to be_truthy
      end
    end

    context 'when user is not group-managed' do
      it 'does not allow adding user to project' do
        expect(subject.can_add_user?(create(:user))).to be_falsey
      end
    end
  end
end
