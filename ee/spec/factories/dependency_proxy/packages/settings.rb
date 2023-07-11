# frozen_string_literal: true

FactoryBot.define do
  factory :dependency_proxy_packages_setting, class: 'DependencyProxy::Packages::Setting' do
    project
    # at least one registry url has to be set, see the AnyFieldValidator set on the model
    maven_external_registry_url { 'http://local.test/maven' }
    enabled { true }

    trait :maven do
      maven_external_registry_username { 'user' }
      maven_external_registry_password { 'password' }
    end

    trait :disabled do
      enabled { false }
    end
  end
end
