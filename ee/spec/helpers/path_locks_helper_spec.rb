# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PathLocksHelper do
  let(:user) { create(:user, name: 'John') }
  let(:user_2) { create(:user, name: 'Bob') }
  let(:path_lock) { create(:path_lock, path: 'app', user: user) }
  let(:project) { create(:project) }

  describe '#can_unlock?' do
    it "returns false if the user is not a project member" do
      allow(self).to receive(:can?).and_return(false)

      expect(can_unlock?(path_lock, user, project)).to be(false)
    end

    it "returns false if the user is not the lock owner" do
      project.add_user(user_2, :developer)
      allow(self).to receive(:can?).and_return(false)

      expect(can_unlock?(path_lock, user_2, project)).to be(false)
    end

    it "returns true if the user has admin_path_locks permission" do
      allow(self).to receive(:can?).with(user, :admin_path_locks, project).and_return(true)

      expect(can_unlock?(path_lock, user, project)).to be(true)
    end

    it "returns true if the user is the lock owner and a project member" do
      project.add_user(user, :developer)
      allow(self).to receive(:can?).and_return(false)

      expect(can_unlock?(path_lock, user, project)).to be(true)
    end
  end

  describe '#text_label_for_lock' do
    it "return correct string for non-nested locks" do
      expect(text_label_for_lock(path_lock, 'app')).to eq('Locked by John')
    end

    it "return correct string for nested locks" do
      expect(text_label_for_lock(path_lock, 'app/models')).to eq('John has a lock on "app"')
    end
  end
end
