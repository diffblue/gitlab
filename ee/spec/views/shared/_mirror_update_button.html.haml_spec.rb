# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/mirror_update_button' do
  let(:partial) { 'shared/mirror_update_button' }

  let_it_be(:project) { create(:project, :mirror) }

  let(:import_state) { project.import_state }

  let(:owner) { project.first_owner }
  let(:developer) { create(:user).tap { |user| project.team.add_developer(user) } }
  let(:reporter) { create(:user).tap { |user| project.team.add_reporter(user) } }

  let(:update_link) { update_now_project_mirror_path(project) }
  let(:have_update_button) { have_link('Update Now', href: update_link) }

  before do
    @project = project
  end

  subject { rendered }

  context 'mirror update can be triggered' do
    context 'user is owner' do
      it 'renders a working update button' do
        render partial, current_user: owner

        is_expected.to have_update_button
      end
    end

    context 'user is developer' do
      it 'renders a disabled update button' do
        render partial, current_user: developer

        is_expected.to have_text('Update Now')
        is_expected.not_to have_update_button
      end
    end

    context 'user is anonymous' do
      it 'renders nothing' do
        render partial, current_user: nil

        is_expected.to eq('')
      end
    end
  end

  context 'mirror update due' do
    it 'renders a disabled update button' do
      expect(import_state).to receive(:mirror_update_due?) { true }
      allow(import_state).to receive(:last_successful_update_at) { Time.now }

      render partial, current_user: owner

      is_expected.to have_text('Scheduled…')
      is_expected.not_to have_update_button
    end
  end

  context 'mirror is currently updating' do
    it 'renders a disabled update button' do
      expect(import_state).to receive(:updating_mirror?) { true }

      render partial, current_user: owner

      is_expected.to have_text('Updating…')
      is_expected.not_to have_update_button
    end
  end

  context 'project is not a mirror' do
    let(:project) { create(:project) }

    it 'renders nothing' do
      is_expected.to eq('')
    end
  end

  it 'renders a notification if the last update succeeded' do
    expect(project).to receive(:mirror_last_update_succeeded?) { true }
    expect(import_state).to receive(:last_successful_update_at) { Time.now }

    render partial, current_user: developer

    is_expected.to have_text('Successfully updated')
  end

  it 'renders no notification if the last update did not succeed' do
    expect(project).to receive(:mirror_last_update_succeeded?) { false }

    render partial, current_user: developer

    is_expected.not_to have_text('Successfully updated')
  end

  it "renders nothing if the user can't push code" do
    render partial, current_user: reporter

    is_expected.to eq('')
  end
end
