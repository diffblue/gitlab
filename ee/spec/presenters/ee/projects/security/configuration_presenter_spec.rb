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
  end
end
