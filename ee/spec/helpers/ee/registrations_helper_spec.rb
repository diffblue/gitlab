# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::RegistrationsHelper do
  include Devise::Test::ControllerHelpers

  describe '#signup_username_data_attributes' do
    it 'has expected attributes' do
      expect(helper.signup_username_data_attributes.keys).to include(:api_path)
    end
  end

  describe '#shuffled_registration_objective_options' do
    subject(:shuffled_options) { helper.shuffled_registration_objective_options }

    it 'has values that match all UserDetail registration objective keys' do
      shuffled_option_values = shuffled_options.map { |item| item.last }

      expect(shuffled_option_values).to contain_exactly(*UserDetail.registration_objectives.keys)
    end

    it '"other" is always the last option' do
      expect(shuffled_options.last).to eq(['A different reason', 'other'])
    end

    context 'when the bypass_registration experiment is candidate', :experiment do
      before do
        stub_experiments({ bypass_registration: :candidate })
      end

      it "excludes the joining_team option" do
        shuffled_option_values = shuffled_options.map { |item| item.last }
        expect(shuffled_option_values).to contain_exactly(*UserDetail.registration_objectives.keys.reject {|k| k == "joining_team"})
      end
    end
  end
end
