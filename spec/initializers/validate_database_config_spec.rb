# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validate database config' do
  let(:rails_configuration) { Rails::Application::Configuration.new(Rails.root) }
  let(:ar_configurations) { ActiveRecord::DatabaseConfigurations.new(rails_configuration.database_configuration) }

  subject do
    load Rails.root.join('config/initializers/validate_database_config.rb')
  end

  before do
    # The `AS::ConfigurationFile` calls `read` in `def initialize`
    # thus we cannot use `expect_next_instance_of`
    # rubocop:disable RSpec/AnyInstanceOf
    expect_any_instance_of(ActiveSupport::ConfigurationFile)
      .to receive(:read).with(Rails.root.join('config/database.yml')).and_return(database_yml)
    # rubocop:enable RSpec/AnyInstanceOf

    allow(Rails.application).to receive(:configuration) { rails_configuration }
    allow(ActiveRecord::Base).to receive(:configurations) { ar_configurations }
  end

  context 'when config/database.yml is valid' do
    context 'uses legacy syntax' do
      let(:database_yml) do
        <<-EOS
          production:
            adapter: postgresql
            encoding: unicode
            database: gitlabhq_production
            username: git
            password: "secure password"
            host: localhost
        EOS
      end

      it 'validates configuration with a warning' do
        expect(Kernel).not_to receive(:warn).with /uses a deprecated syntax for/

        expect { subject }.not_to raise_error
      end
    end

    context 'uses new syntax' do
      let(:database_yml) do
        <<-EOS
          production:
            main:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production
              username: git
              password: "secure password"
              host: localhost
        EOS
      end

      it 'validates configuration without errors and warnings' do
        expect(Kernel).not_to receive(:warn)

        expect { subject }.not_to raise_error
      end
    end
  end

  context 'when config/database.yml is invalid' do
    context 'uses unknown connection name' do
      let(:database_yml) do
        <<-EOS
          production:
            main:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production
              username: git
              password: "secure password"
              host: localhost

            another:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production
              username: git
              password: "secure password"
              host: localhost
        EOS
      end

      it 'raises exception' do
        expect { subject }.to raise_error /This installation of GitLab uses unsupported database names/
      end
    end

    context 'uses replica configuration' do
      let(:database_yml) do
        <<-EOS
          production:
            main:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production
              username: git
              password: "secure password"
              host: localhost
              replica: true
        EOS
      end

      it 'raises exception' do
        expect { subject }.to raise_error /with 'replica: true' parameter in/
      end
    end

    context 'main is not a first entry' do
      let(:database_yml) do
        <<-EOS
          production:
            ci:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production_ci
              username: git
              password: "secure password"
              host: localhost
              replica: true

            main:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production
              username: git
              password: "secure password"
              host: localhost
              replica: true
        EOS
      end

      it 'raises exception' do
        expect { subject }.to raise_error /The `main:` database needs to be defined as a first configuration item/
      end
    end
  end
end
