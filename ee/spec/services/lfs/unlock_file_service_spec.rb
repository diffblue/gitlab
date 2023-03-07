# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lfs::UnlockFileService, feature_category: :source_code_management do
  let(:project)      { create(:project) }
  let(:lock_author)  { create(:user) }
  let!(:lock)        { create(:lfs_file_lock, user: lock_author, project: project) }

  subject { described_class.new(project, current_user, params) }

  describe '#execute' do
    context 'when authorized' do
      before do
        project.add_developer(current_user)
      end

      describe 'File Locking integraction' do
        let(:params) { { id: lock.id } }
        let(:current_user) { lock_author }
        let(:file_locks_license) { true }

        before do
          stub_licensed_features(file_locks: file_locks_license)

          project.add_developer(lock_author)
          project.path_locks.create!(path: lock.path, user: lock_author)
        end

        context 'when File Locking is available' do
          it 'deletes the Path Lock' do
            expect { subject.execute }.to change { PathLock.count }.to(0)
          end
        end

        context 'when File Locking is not available' do
          let(:file_locks_license) { false }

          it 'does not delete the Path Lock' do
            expect { subject.execute }.not_to change { PathLock.count }
          end
        end
      end
    end
  end
end
