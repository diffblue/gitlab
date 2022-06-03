# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::RunnersController do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#show' do
    let(:runner) { create(:ci_runner) }

    it 'enables runner_maintenance_note licensed feature' do
      is_expected.to receive(:push_licensed_feature).with(:runner_maintenance_note)

      get :show, params: { id: runner }
    end
  end

  describe '#edit' do
    let(:runner) { create(:ci_runner) }

    it 'enables runner_maintenance_note licensed feature' do
      is_expected.to receive(:push_licensed_feature).with(:runner_maintenance_note)

      get :edit, params: { id: runner }
    end
  end
end
