# frozen_string_literal: true

RSpec.shared_context 'group managed account with group members' do
  let(:group) { create :group_with_managed_accounts }
  let(:member) { create :user, :group_managed }
  let(:gma_member) { create :user, :group_managed, managing_group: group }

  before do
    stub_licensed_features(group_saml: true)

    group.add_maintainer(member)
    group.add_maintainer(gma_member)
  end
end

RSpec.shared_context 'group managed account with project members' do
  let(:group) { create :group_with_managed_accounts }
  let(:member) { create :user, :group_managed }
  let(:gma_member) { create :user, managing_group: group }

  before do
    project.add_maintainer(member)
    project.add_maintainer(gma_member)

    stub_licensed_features(group_saml: true)
  end
end

RSpec.shared_context 'child group with group managed account members' do
  let(:child_group) { create :group, parent: group }
  let(:child_member) { create :user, :group_managed }
  let(:child_gma_member) { create :user, :group_managed, managing_group: group }

  before do
    child_group.add_owner(owner)

    child_group.add_developer(child_member)
    child_group.add_developer(child_gma_member)
  end
end

RSpec.shared_context 'child project with group managed account members' do
  let(:child_group) { create :group, parent: group }
  let(:child_project) { create :project, group: child_group }
  let(:child_member) { create :user, :group_managed }
  let(:child_gma_member) { create :user, :group_managed, managing_group: group }

  before do
    child_group.add_owner(owner)

    child_project.add_developer(child_member)
    child_project.add_developer(child_gma_member)
  end
end
