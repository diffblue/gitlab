# frozen_string_literal: true

FactoryBot.define do
  factory :spdx_catalogue, class: '::Gitlab::SPDX::Catalogue' do
    initialize_with do
      content = File.read(Rails.root.join('spec', 'fixtures', 'spdx.json'))
      ::Gitlab::SPDX::Catalogue.new(Gitlab::Json.parse(content, symbolize_names: true))
    end

    skip_create
  end
end
