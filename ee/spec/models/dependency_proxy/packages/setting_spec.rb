# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::Packages::Setting, type: :model, feature_category: :dependency_proxy do
  using RSpec::Parameterized::TableSyntax

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:dependency_proxy_packages_setting) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    context 'for maven registry url' do
      where(:url, :valid, :error_message) do
        'http://test.maven'   | true  | nil
        'https://test.maven'  | true  | nil
        'git://test.maven'    | false | 'Maven external registry url is blocked: Only allowed schemes are http, https'
        nil                   | false | 'At least one field of ["maven_external_registry_url"] must be present'
        ''                    | false | 'At least one field of ["maven_external_registry_url"] must be present'
        "http://#{'a' * 255}" | false | 'Maven external registry url is too long (maximum is 255 characters)'
      end

      with_them do
        let(:setting) { build(:dependency_proxy_packages_setting, maven_external_registry_url: url) }

        if params[:valid]
          it { expect(setting).to be_valid }
        else
          it do
            expect(setting).not_to be_valid
            expect(setting.errors).to contain_exactly(error_message)
          end
        end
      end
    end

    context 'for maven credentials' do
      where(:maven_username, :maven_password, :valid, :error_message) do
        'user'      | 'password'   | true  | nil
        ''          | ''           | true  | nil
        ''          | nil          | true  | nil
        nil         | ''           | true  | nil
        nil         | 'password'   | false | "Maven external registry username can't be blank"
        'user'      | nil          | false | "Maven external registry password can't be blank"
        ''          | 'password'   | false | "Maven external registry username can't be blank"
        'user'      | ''           | false | "Maven external registry password can't be blank"
        ('a' * 256) | 'password'   | false | "Maven external registry username is too long (maximum is 255 characters)"
        'user'      | ('a' * 256)  | false | "Maven external registry password is too long (maximum is 255 characters)"
      end

      with_them do
        let(:setting) do
          build(
            :dependency_proxy_packages_setting,
            :maven,
            maven_external_registry_username: maven_username,
            maven_external_registry_password: maven_password
          )
        end

        if params[:valid]
          it { expect(setting).to be_valid }
        else
          it do
            expect(setting).not_to be_valid
            expect(setting.errors).to contain_exactly(error_message)
          end
        end
      end
    end
  end

  describe '.enabled' do
    let_it_be(:enabled_setting) { create(:dependency_proxy_packages_setting) }
    let_it_be(:disabled_setting) { create(:dependency_proxy_packages_setting, :disabled) }

    subject { described_class.enabled }

    it { is_expected.to contain_exactly(enabled_setting) }
  end
end
