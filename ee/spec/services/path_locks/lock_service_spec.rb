# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PathLocks::LockService, feature_category: :source_code_management do
  let(:current_user) { create(:user) }
  let(:project)      { create(:project) }
  let(:path)         { 'app/models' }

  it 'locks path' do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:can?).and_return(true)
    end
    described_class.new(project, current_user).execute(path)

    expect(project.path_locks.find_by(path: path)).to be_truthy
  end

  it 'raises exception if user has no permissions' do
    expect do
      described_class.new(project, current_user).execute(path)
    end.to raise_exception(PathLocks::LockService::AccessDenied)
  end
end
