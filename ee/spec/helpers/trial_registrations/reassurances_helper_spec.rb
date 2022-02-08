# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialRegistrations::ReassurancesHelper do
  describe '#reassurance_logo_data' do
    it 'returns a collection of data in the expected format' do
      expect(reassurance_logo_data).to all(match({
        name: an_instance_of(String),
        css_classes: a_string_matching(/\Agl-w-\d+ gl-h-\d+ gl-mr-\d+ gl-opacity-\d+\z/),
        image_path: a_string_matching(%r{\Aillustrations/third-party-logos/[a-z0-9-]+\.svg\z}),
        image_alt_text: a_string_ending_with(' logo')
      }))
    end
  end
end
