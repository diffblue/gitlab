# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Automated License Installation' do
  subject { load Rails.root.join('ee', 'db', 'fixtures', 'production', '010_license.rb') }

  it 'executes the gitlab:license:load task' do
    expect(Rake::Task).to receive(:[]).with('gitlab:license:load').and_return(double('license', invoke: true))

    subject
  end
end
