# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMemberPresenter do
  let(:user) { double(:user) }
  let(:project) { double(:project) }
  let(:project_member) { double(:project_member, source: project) }
  let(:presenter) { described_class.new(project_member, current_user: user) }

  describe '#group_sso?' do
    it 'returns `false`' do
      expect(presenter.group_sso?).to eq(false)
    end
  end

  describe '#group_managed_account?' do
    it 'returns `false`' do
      expect(presenter.group_managed_account?).to eq(false)
    end
  end

  describe '#can_update?' do
    context 'when user cannot update project_member' do
      before do
        allow(project_member).to receive(:owner?).and_return(false)
        allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(false)
      end

      context 'when user can override_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :override_project_member, presenter).and_return(true)
        end

        it { expect(presenter.can_update?).to eq(true) }
      end

      context 'when user cannot override_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :override_project_member, presenter).and_return(false)
        end

        it { expect(presenter.can_update?).to eq(false) }
      end
    end
  end

  describe '#can_ban?' do
    it { expect(presenter.can_ban?).to eq(false) }
  end

  describe '#can_unban?' do
    it { expect(presenter.can_unban?).to eq(false) }
  end
end
