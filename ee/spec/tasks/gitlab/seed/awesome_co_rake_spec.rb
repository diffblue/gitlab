# frozen_string_literal: true

require 'rake_helper'

module AwesomeCo
  RSpec.describe 'ee:gitlab:seed:awesome_co', feature_category: :dataops do
    let(:seed_file_name) { 'seed.rb' }
    let(:seed_file_content) { '' }
    let!(:seed_file) do
      Tempfile.open(seed_file_name) do |f|
        f.write(seed_file_content)
        f
      end
    end

    let(:namespace) { class_spy('Namespace') }

    before do
      Rake.application.rake_require 'tasks/gitlab/seed/awesome_co'
      stub_const('Namespace', namespace)

      allow(namespace).to receive(:find).with('1').and_return(Struct.new(:name).new)
    end

    context 'when seed file does not exist' do
      let(:seed_file) { 'invalid' }

      it 'raises an error' do
        expect { run_rake }.to raise_error(/Seed file `.*invalid` does not exist/)
      end
    end

    it 'prints a seeding statement' do
      expect { run_rake }.to output(/Seeding AwesomeCo demo data/).to_stdout
    end

    private

    def run_rake
      run_rake_task('ee:gitlab:seed:awesome_co', File.absolute_path(seed_file), 1)
    end
  end
end
