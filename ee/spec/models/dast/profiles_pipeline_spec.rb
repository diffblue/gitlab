# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::ProfilesPipeline, type: :model do
  subject { create(:dast_profiles_pipeline) }

  describe 'associations' do
    it { is_expected.to belong_to(:ci_pipeline).class_name('Ci::Pipeline').required }
    it { is_expected.to belong_to(:dast_profile).class_name('Dast::Profile').required }
  end
end
