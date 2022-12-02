# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Projects::SetLocked do
  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  describe '#resolve' do
    subject { mutation.resolve(project_path: project.full_path, file_path: file_path, lock: lock) }

    let(:file_path) { 'README.md' }
    let(:lock) { true }
    let(:mutated_path_locks) { subject[:project].path_locks }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can lock the file' do
      let(:lock) { true }

      before do
        project.add_developer(user)
      end

      context 'when file_locks feature is not available' do
        before do
          stub_licensed_features(file_locks: false)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when file is not locked' do
        it 'sets path locks for the project' do
          expect { subject }.to change { project.path_locks.count }.by(1)
          expect(mutated_path_locks.first).to have_attributes(path: file_path, user: user)
        end
      end

      context 'when file is already locked' do
        before do
          create(:path_lock, project: project, path: file_path)
        end

        it 'does not change the lock' do
          expect { subject }.not_to change { project.path_locks.count }
        end
      end

      context 'when LFS is enabled' do
        let(:file_path) { 'files/lfs/lfs_object.iso' }

        before do
          allow_next_found_instance_of(Project) do |project|
            allow(project).to receive(:lfs_enabled?).and_return(true)
          end
        end

        it 'locks the file in LFS' do
          expect { subject }.to change { project.lfs_file_locks.count }.by(1)
        end

        context 'when file is not tracked in LFS' do
          let(:file_path) { 'README.md' }

          it 'does not lock the file' do
            expect { subject }.not_to change { project.lfs_file_locks.count }
          end
        end

        context 'when locking a directory' do
          let(:file_path) { 'lfs/' }

          it 'locks the directory' do
            expect { subject }.to change { project.path_locks.count }.by(1)
          end

          it 'does not locks the directory through LFS' do
            expect { subject }.not_to change { project.lfs_file_locks.count }
          end
        end
      end
    end

    context 'when the user can unlock the file' do
      let(:lock) { false }

      before do
        project.add_developer(user)
      end

      context 'when file is already locked by the same user' do
        before do
          create(:path_lock, project: project, path: file_path, user: user)
        end

        it 'unlocks the file' do
          expect { subject }.to change { project.path_locks.count }.by(-1)
          expect(mutated_path_locks).to be_empty
        end
      end

      context 'when file is already locked by somebody else' do
        before do
          create(:path_lock, project: project, path: file_path)
        end

        it 'returns an error' do
          expect(subject[:errors]).to eq(['You have no permissions'])
        end
      end

      context 'when file is not locked' do
        it 'does nothing' do
          expect { subject }.not_to change { project.path_locks.count }
          expect(mutated_path_locks).to be_empty
        end
      end

      context 'when LFS is enabled' do
        let(:file_path) { 'files/lfs/lfs_object.iso' }

        before do
          allow_next_found_instance_of(Project) do |project|
            allow(project).to receive(:lfs_enabled?).and_return(true)
          end
        end

        context 'when file is locked' do
          before do
            create(:lfs_file_lock, project: project, path: file_path, user: user)
            create(:path_lock, project: project, path: file_path, user: user)
          end

          it 'unlocks the file' do
            expect { subject }.to change { project.path_locks.count }.by(-1)
          end

          it 'unlocks the file in LFS' do
            expect { subject }.to change { project.lfs_file_locks.count }.by(-1)
          end

          context 'when file is not tracked in LFS' do
            let(:file_path) { 'README.md' }

            it 'does not unlock the file' do
              expect { subject }.not_to change { project.lfs_file_locks.count }
            end
          end

          context 'when unlocking a directory' do
            let(:file_path) { 'lfs/' }

            it 'unlocks the directory' do
              expect { subject }.to change { project.path_locks.count }.by(-1)
            end

            it 'does not call the LFS unlock service' do
              expect(Lfs::UnlockFileService).not_to receive(:new)

              subject
            end
          end
        end
      end
    end
  end
end
