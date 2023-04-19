# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::AiHelper, type: :helper, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let(:user) { build_stubbed(:user) }

  describe '#check_feature_enabled!' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when openai_experimentation feature is disabled' do
      before do
        stub_feature_flags(openai_experimentation: false)
      end

      it 'raises not found' do
        expect(helper).to receive(:not_found!)

        helper.check_feature_enabled!
      end
    end

    context 'when ai_experimentation_api feature is disabled' do
      before do
        stub_feature_flags(ai_experimentation_api: false)
      end

      it 'raises not found' do
        expect(helper).to receive(:not_found!)

        helper.check_feature_enabled!
      end
    end

    it 'returns nil' do
      expect(helper.check_feature_enabled!).to eq(nil)
    end
  end
end
