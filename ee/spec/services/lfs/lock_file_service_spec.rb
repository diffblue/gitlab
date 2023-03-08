# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lfs::LockFileService, feature_category: :source_code_management do
  let(:project)      { create(:project) }
  let(:current_user) { create(:user) }
  let(:params) { { path: 'README.md' } }

  subject { described_class.new(project, current_user, params) }

  describe '#execute' do
    context 'when authorized' do
      before do
        project.add_developer(current_user)
      end

      context 'when File Locking is available' do
        before do
          stub_licensed_features(file_locks: true)
        end

        it 'creates the Path Lock' do
          expect { subject.execute }.to change { PathLock.count }.to(1)
        end
      end

      context 'when File Locking is not available' do
        before do
          stub_licensed_features(file_locks: false)
        end

        it 'does not create the Path Lock' do
          expect { subject.execute }.not_to change { PathLock.count }
        end
      end
    end
  end
end
