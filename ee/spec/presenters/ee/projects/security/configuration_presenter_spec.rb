# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ConfigurationPresenter do
  include Gitlab::Routing.url_helpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }

  describe '#to_h' do
    subject(:result) { described_class.new(project, auto_fix_permission: true, current_user: current_user).to_h }

    it 'includes settings for auto_fix feature' do
      auto_fix = result[:auto_fix_enabled]

      expect(auto_fix[:dependency_scanning]).to be_truthy
      expect(auto_fix[:container_scanning]).to be_truthy
    end

    it 'reports auto_fix permissions' do
      expect(result[:can_toggle_auto_fix_settings]).to be_truthy
    end

    it 'reports security_training_enabled' do
      allow(project).to receive(:security_training_available?).and_return(true)

      expect(result[:security_training_enabled]).to be_truthy
    end
  end

  describe '#to_html_data_attribute' do
    subject(:result) { described_class.new(project, auto_fix_permission: true, current_user: current_user).to_h }

    before do
      stub_licensed_features(security_on_demand_scans: true, security_configuration_in_ui: true)
    end

    let(:meta_info_path) { "/#{project.full_path}/-/on_demand_scans" }
    let(:features) { result[:features] }

    it 'includes feature meta information for dast scanner' do
      feature = features.find { |scan| scan[:type].to_s == 'dast' }

      expect(feature[:type].to_s).to eq('dast')
      expect(feature[:meta_info_path]).to eq(meta_info_path)
    end

    it 'does not include feature meta information for other scanner' do
      feature = features.find { |scan| scan[:type].to_s == 'sast' }

      expect(feature[:type].to_s).to eq('sast')
      expect(feature[:meta_info_path]).to be_nil
    end
  end
end
