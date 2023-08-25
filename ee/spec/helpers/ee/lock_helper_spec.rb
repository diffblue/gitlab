# frozen_string_literal: true

require "spec_helper"

RSpec.describe EE::LockHelper do
  describe '#lock_file_link' do
    let!(:path_lock) { create :path_lock, path: 'app/models' }
    let(:path) { path_lock.path }
    let(:user) { path_lock.user }
    let(:project) { path_lock.project }
    let_it_be(:disabled_attr) { 'disabled="disabled"' }

    before do
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      allow(project).to receive(:feature_available?).with(:file_locks) { true }

      project.reload
    end

    context 'when there is no lock' do
      let(:subject) { helper.lock_file_link(project, '.gitignore') }
      let_it_be(:tooltip_text) { "You do not have permission to lock this" }

      context 'when user can push code to the project' do
        it 'returns an enabled "Lock" button without a tooltip' do
          expect(subject).to match('Lock')
          expect(subject).not_to match(disabled_attr)
          expect(subject).not_to match(tooltip_text)
        end
      end

      context 'when user cannot push code to the project' do
        before do
          allow(helper).to receive(:can?).and_return(false)
        end

        it 'returns a disabled "Lock" button with a tooltip' do
          expect(subject).to match('Lock')
          expect(subject).to match(disabled_attr)
          expect(subject).to match(tooltip_text)
        end
      end
    end

    context 'when there is no conflicting lock' do
      let(:subject) { helper.lock_file_link(project, path) }
      let_it_be(:tooltip_text) { "Locked by" }

      context 'when user is allowed to unlock the path' do
        context 'when path was locked by the current user' do
          it 'returns an enabled "Unlock" button without a tooltip' do
            expect(subject).to match('Unlock')
            expect(subject).not_to match(disabled_attr)
            expect(subject).not_to match(tooltip_text)
          end
        end

        context 'wnen path was locked by someone else' do
          let(:user2) { create :user }

          before do
            allow(helper).to receive(:current_user).and_return(user2)
          end

          it 'returns an enabled "Unlock" button with a tooltip' do
            expect(subject).to match('Unlock')
            expect(subject).not_to match(disabled_attr)
            expect(subject).to match(tooltip_text)
          end
        end
      end

      context 'when user is not allowed to unlock the path' do
        before do
          allow(helper).to receive(:can?).and_return(false)
        end

        it 'returns a disabled "Unlock" button with a tooltip' do
          expect(subject).to match('Unlock')
          expect(subject).to match(disabled_attr)
          expect(subject).to match(tooltip_text)
        end
      end
    end

    context 'when there is an upstream lock' do
      let(:requested_path) { 'app/models/user.rb' }
      let(:subject) { helper.lock_file_link(project, requested_path) }

      context 'when user is allowed to unlock the upstream path' do
        it 'returns a disabled "Unlock" button with a tooltip' do
          expect(subject).to match('Unlock')
          expect(subject).to match(disabled_attr)
          expect(subject).to match("Unlock that directory in order to unlock this")
        end
      end

      context 'when user is not allowed to unlock the upstream path' do
        before do
          allow(helper).to receive(:can?).and_return(false)
        end

        it 'returns a disabled "Unlock" button with a tooltip' do
          expect(subject).to match('Unlock')
          expect(subject).to match(disabled_attr)
          expect(subject).to match("You do not have permission to unlock it")
        end
      end
    end

    context 'when there is a downstream lock' do
      let(:subject) { helper.lock_file_link(project, 'app') }

      context 'when user is allowed to unlock the downstream path' do
        it 'returns a disabled "Lock" button with a tooltip' do
          expect(subject).to match('Lock')
          expect(subject).to match(disabled_attr)
          expect(subject).to match("Unlock this in order to proceed")
        end
      end

      context 'when user is not allowed to unlock the downstream path' do
        before do
          allow(helper).to receive(:can?).and_return(false)
        end

        it 'returns a disabled "Lock" button with a tooltip' do
          expect(subject).to match('Lock')
          expect(subject).to match(disabled_attr)
          expect(subject).to match("You do not have permission to unlock it")
        end
      end
    end
  end
end
