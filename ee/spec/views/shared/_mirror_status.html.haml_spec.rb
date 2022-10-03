# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_mirror_status.html.haml' do
  include ApplicationHelper

  let(:project) { create(:project, :mirror, import_state: import_state) }

  before do
    @project = project # for the view

    sign_in(project.first_owner)
  end

  context 'when mirror has not updated yet' do
    let(:import_state) { create(:import_state) }

    it 'does not render anything' do
      render 'shared/mirror_status'

      expect(rendered).to be_empty
    end
  end

  context 'when mirror successful' do
    let(:import_state) { create(:import_state, :finished) }

    it 'renders success message' do
      render 'shared/mirror_status'

      expect(rendered).to have_content("Pull mirroring updated")
    end
  end

  context 'when mirror failed' do
    let(:import_state) { create(:import_state, :failed) }

    it 'renders failure message' do
      render 'shared/mirror_status', raw_message: true

      expect(rendered).to have_content("Pull mirroring failed")
    end

    it 'renders failure message with icon' do
      render 'shared/mirror_status'

      expect(rendered).to have_content("Pull mirroring failed")

      expect(rendered).to have_selector('[data-testid="warning-solid-icon"]')
    end

    context 'with a previous successful update' do
      let(:import_state) { create(:import_state, :failed, last_successful_update_at: Time.now - 1.minute) }

      it 'renders failure message' do
        render 'shared/mirror_status', raw_message: true

        expect(rendered).to have_content("Last successful update")
      end
    end

    context 'with a hard failed mirror' do
      let(:import_state) { create(:import_state, :failed, retry_count: Gitlab::Mirror::MAX_RETRY + 1) }

      it 'renders hard failed message' do
        render 'shared/mirror_status', raw_message: true

        expect(rendered).to have_content("Repository mirroring has been paused due to too many failed attempts. It can be resumed by a project maintainer or owner.")
      end
    end
  end
end
