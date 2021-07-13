# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectPresenter do
  include Gitlab::Routing.url_helpers

  let(:user) { create(:user) }

  describe '#extra_statistics_buttons' do
    let(:project) { create(:project) }
    let(:presenter) { described_class.new(project, current_user: user) }

    it { expect(presenter.extra_statistics_buttons).to be_empty }

    context 'when the sast entry points experiment is enabled' do
      before do
        allow(presenter).to receive(:sast_entry_points_experiment_enabled?).with(project).and_return(true)
      end

      it 'has the sast help page button' do
        expect(presenter.extra_statistics_buttons.find { |button| button[:link] == help_page_path('user/application_security/sast/index') }).not_to be_nil
      end
    end
  end
end
