# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::RegistrationsHelper do
  describe '#signup_username_data_attributes' do
    it 'has expected attributes' do
      expect(helper.signup_username_data_attributes.keys).to include(:api_path)
    end
  end

  describe '#shuffled_jobs_to_be_done_options' do
    subject { helper.shuffled_jobs_to_be_done_options }

    let(:array_double) { double(:array) }

    it 'uses shuffle' do
      allow(helper).to receive(:jobs_to_be_done_options).and_return(array_double)

      expect(array_double).to receive(:shuffle).and_return([])

      subject
    end

    it 'has a number of options' do
      expect(subject.count).to eq(7)
    end

    it '"other" is always the last option' do
      expect(subject.last).to eq(['A different reason', 'other'])
    end
  end
end
