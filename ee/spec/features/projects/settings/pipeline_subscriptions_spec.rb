# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Subscriptions', :js, feature_category: :pipeline_composition do
  let(:project) { create(:project, :public, :repository) }
  let(:upstream_project) { create(:project, :public, :repository) }
  let(:downstream_project) { create(:project, :public, :repository, upstream_projects: [project]) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    upstream_project.add_maintainer(user)
    downstream_project.add_maintainer(user)

    stub_licensed_features(ci_project_subscriptions: true)

    sign_in(user)
    visit project_settings_ci_cd_path(project)
  end

  it 'renders the correct path for the form action' do
    within '#pipeline-subscriptions' do
      form_action = find('#pipeline-subscriptions-form')['action']

      expect(form_action).to end_with("/#{project.full_path}/-/subscriptions")
    end
  end

  it 'renders the list of downstream projects' do
    within '[data-testid="downstream-project-subscriptions"]' do
      expect(find('.badge-pill').text).to eq '1'
    end

    expect(page).to have_content(downstream_project.name)
    expect(page).to have_content(downstream_project.owner.name)
  end

  it 'doesn\'t allow to delete downstream projects' do
    within '[data-testid="downstream-project-subscriptions"]' do
      expect(page).not_to have_content('[data-testid="delete-subscription"]')
    end
  end

  it 'successfully creates new pipeline subscription' do
    within '#pipeline-subscriptions' do
      within 'form' do
        fill_in 'upstream_project_path', with: upstream_project.full_path

        click_on 'Subscribe'
      end

      within '[data-testid="upstream-project-subscriptions"]' do
        expect(find('.badge-pill').text).to eq '1'
      end

      expect(page).to have_content(upstream_project.name)
      expect(page).to have_content(upstream_project.namespace.name)
    end

    expect(page).to have_content('Subscription successfully created.')
  end

  it 'shows flash warning when unsuccesful in creating a pipeline subscription' do
    within '#pipeline-subscriptions' do
      within 'form' do
        fill_in 'upstream_project_path', with: 'wrong/path'

        click_on 'Subscribe'
      end

      within '[data-testid="upstream-project-subscriptions"]' do
        expect(find('.badge-pill').text).to eq '0'
        expect(page).to have_content('This project is not subscribed to any project pipelines.')
      end
    end

    expect(page).to have_content('This project path either does not exist or you do not have access.')
  end

  it 'subscription is removed successfully' do
    within '#pipeline-subscriptions' do
      within 'form' do
        fill_in 'upstream_project_path', with: upstream_project.full_path

        click_on 'Subscribe'
      end
    end

    find('[data-testid="delete-subscription"]').click

    expect(page).to have_content('Subscription successfully deleted.')
  end
end
