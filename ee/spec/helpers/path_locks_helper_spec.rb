# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PathLocksHelper do
  let(:user) { create(:user, name: 'John') }
  let(:project) { create(:project) }
  let(:path_lock) { create(:path_lock, path: 'app', user: user, project: project) }

  describe '#can_unlock?' do
    it "returns true if the user has admin_path_locks permission" do
      allow(self).to receive(:can?).with(user, :admin_path_locks, path_lock).and_return(true)

      expect(can_unlock?(path_lock, user)).to be(true)
    end

    it "returns false if the user does not have admin_path_locks permission" do
      allow(self).to receive(:can?).with(user, :admin_path_locks, path_lock).and_return(false)

      expect(can_unlock?(path_lock, user)).to be(false)
    end
  end

  describe '#text_label_for_lock' do
    it "return correct string for non-nested locks" do
      expect(text_label_for_lock(path_lock, 'app')).to eq("Locked by #{user.username}")
    end

    it "return correct string for nested locks" do
      expect(text_label_for_lock(path_lock, 'app/models')).to eq("#{user.username} has a lock on \"app\"")
    end
  end
end
