# frozen_string_literal: true

RSpec.shared_examples 'status page quick actions' do
  describe '/publish' do
    let_it_be(:status_page_setting) { create(:status_page_setting, :enabled, project: project) }

    let(:user) { project.first_owner }

    before do
      stub_licensed_features(status_page: true)
    end

    shared_examples 'skip silently' do
      it 'does not allow publishing' do
        expect(Gitlab::StatusPage).not_to receive(:mark_for_publication).with(project, user, issue)
        expect(StatusPage::PublishWorker).not_to receive(:perform_async).with(user.id, project.id, issue.id)

        add_note('/publish')

        expect(page).not_to have_content('Issue published on status page.')
        expect(page).not_to have_content('Failed to publish issue on status page.')
      end
    end

    it 'publishes the issue' do
      expect(StatusPage::PublishWorker).to receive(:perform_async).with(user.id, project.id, issue.id)

      add_note('/publish')

      expect(page).to have_content('Issue published on status page.')
    end

    context 'during issue creation' do
      it 'publishes the issue' do
        visit new_project_issue_path(project)

        fill_in('Title', with: 'Title')
        fill_in('Description', with: "Published issue \n\n/publish")
        click_button('Create issue')

        wait_for_requests

        expect(page).to have_content('Published issue')
        expect(page).to have_content("#{user.name} published this issue to the status page")
      end
    end

    context 'publishing causes an error' do
      it 'provides an error message' do
        allow(StatusPage::PublishedIncident).to receive(:track).with(issue).and_raise('Error')

        add_note('/publish')

        expect(page).not_to have_content("#{user.name} published this issue to the status page")
        expect(page).to have_content('Failed to publish issue on status page.')
      end
    end

    context 'user does not have permissions' do
      let(:user) { create(:user) }

      it_behaves_like 'skip silently'
    end

    context 'status page is not configured' do
      before do
        status_page_setting.update!(enabled: false)
      end

      after do
        status_page_setting.update!(enabled: true)
      end

      it_behaves_like 'skip silently'
    end

    context 'issue is already published' do
      before do
        create(:status_page_published_incident, issue: issue)
      end

      it_behaves_like 'skip silently'
    end
  end
end
