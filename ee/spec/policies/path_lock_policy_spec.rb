# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PathLockPolicy do
  let(:project) { create(:project) }
  let(:maintainer) { create(:user) }
  let(:developer) { create(:user) }
  let(:non_member) { create(:user) }

  let(:developer_path_lock) { create(:path_lock, user: developer, project: project) }
  let(:non_member_path_lock) { create(:path_lock, user: non_member, project: project) }

  before do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
  end

  def permissions(user, path_lock)
    described_class.new(user, path_lock)
  end

  it 'disallows non-member from administrating path lock they created' do
    expect(permissions(non_member, non_member_path_lock)).to be_disallowed(:admin_path_locks)
  end

  it 'disallows developer from administrating path lock they did not create' do
    expect(permissions(developer, non_member_path_lock)).to be_disallowed(:admin_path_locks)
  end

  it 'allows developer to administrating path lock they created' do
    expect(permissions(developer, developer_path_lock)).to be_allowed(:admin_path_locks)
  end

  it 'allows maintainer to administrating path lock they did not create' do
    expect(permissions(maintainer, non_member_path_lock)).to be_allowed(:admin_path_locks)
    expect(permissions(maintainer, developer_path_lock)).to be_allowed(:admin_path_locks)
  end
end
