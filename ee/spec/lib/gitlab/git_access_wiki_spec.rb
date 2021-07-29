# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitAccessWiki do
  include WikiHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :wiki_repo) }

  let(:wiki) { create(:project_wiki, project: project) }
  let(:changes) { ['6f6d7e7ed 570e7b2ab refs/heads/master'] }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }

  let(:access) do
    described_class.new(user, wiki, 'web',
                        authentication_abilities: authentication_abilities,
                        redirected_path: redirected_path)
  end

  before do
    stub_group_wikis(true)
  end

  describe 'group wiki access' do
    let_it_be_with_refind(:group) { create(:group, :private, :wiki_repo) }

    let(:wiki) { create(:group_wiki, group: group) }

    describe '#push_access_check' do
      subject { access.check('git-receive-pack', changes) }

      context 'when user can :create_wiki' do
        before do
          group.add_developer(user)
        end

        it { expect { subject }.not_to raise_error }

        context 'when in a read-only GitLab instance' do
          before do
            allow(Gitlab::Database.main).to receive(:read_only?) { true }
          end

          it 'does not give access to upload wiki code' do
            expect { subject }.to raise_forbidden("You can't push code to a read-only GitLab instance.")
          end
        end

        context 'when group is read-only' do
          it 'does not allow push and allows pull access' do
            allow(group).to receive(:repository_read_only?).and_return(true)

            expect { push_changes(changes) }.to raise_forbidden('The repository is temporarily read-only. Please try again later.')
            expect { pull_changes(changes) }.not_to raise_error
          end
        end

        context 'when the group is renamed' do
          let(:redirected_path) { 'some/other-path' }

          it 'enqueues a redirected message for pushing' do
            subject

            expect(Gitlab::Checks::ContainerMoved.fetch_message(user, wiki.repository)).not_to be_nil
          end
        end
      end

      context 'when user cannot :create_wiki' do
        before do
          group.add_reporter(user)
        end

        specify do
          expect { subject }.to raise_error(Gitlab::GitAccess::ForbiddenError, "You are not allowed to write to this group's wiki.")
        end
      end
    end

    describe '#check_download_access!' do
      subject { access.check('git-upload-pack', Gitlab::GitAccess::ANY) }

      context 'the user has at least reporter access' do
        before do
          group.add_reporter(user)
        end

        context 'when wiki feature is enabled' do
          it 'gives access to download wiki code' do
            expect { subject }.not_to raise_error
          end

          context 'when the wiki repository does not exist' do
            before do
              allow(wiki.repository).to receive(:exists?).and_return(false)
            end

            it_behaves_like 'not-found git access' do
              let(:message) { 'A repository for this group wiki does not exist yet.' }
            end
          end
        end

        context 'when wiki feature is disabled' do
          before do
            stub_group_wikis(false)
          end

          it_behaves_like 'forbidden git access' do
            let(:message) { 'You are not allowed to download files from this wiki.' }
          end
        end
      end

      context 'the user does not have access' do
        it_behaves_like 'not-found git access' do
          let(:message) { 'The group you were looking for could not be found.' }
        end
      end

      context 'when actor is geo' do
        let(:user) { :geo }

        it 'gives access to download wiki code' do
          expect { subject }.not_to raise_error
        end
      end

      context 'the group is public' do
        let(:group) { create(:group, :public, :wiki_repo) }

        it 'gives access to download wiki code' do
          expect { subject }.not_to raise_error
        end

        context 'when wiki feature is disabled' do
          before do
            stub_group_wikis(false)
          end

          it_behaves_like 'forbidden git access' do
            let(:message) { 'You are not allowed to download files from this wiki.' }
          end
        end
      end
    end
  end

  context "when in a read-only GitLab instance" do
    subject { access.check('git-receive-pack', changes) }

    before do
      create(:protected_branch, name: 'feature', project: project)
      allow(Gitlab::Database.main).to receive(:read_only?) { true }
    end

    let(:primary_repo_url) { geo_primary_http_url_to_repo(project.wiki) }
    let(:primary_repo_ssh_url) { geo_primary_ssh_url_to_repo(project.wiki) }

    it_behaves_like 'git access for a read-only GitLab instance'
  end

  context 'when wiki is disabled' do
    let(:user) { :geo }
    let(:project) { create(:project, :private, :wiki_repo, wiki_access_level: ProjectFeature::DISABLED) }
    let(:authentication_abilities) { [:download_code] }

    subject { access.check('git-upload-pack', changes) }

    it 'allows code download for geo' do
      expect(subject).to be_truthy
    end
  end

  private

  def pull_changes(changes = Gitlab::GitAccess::ANY)
    access.check('git-upload-pack', changes)
  end

  def push_changes(changes = Gitlab::GitAccess::ANY)
    access.check('git-receive-pack', changes)
  end

  # It is needed by the shared examples
  def raise_forbidden(message)
    raise_error(Gitlab::GitAccess::ForbiddenError, message)
  end
end
