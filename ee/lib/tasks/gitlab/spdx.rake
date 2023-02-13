# frozen_string_literal: true

namespace :gitlab do
  namespace :spdx do
    desc 'GitLab | SPDX | Import copy of the catalogue to store it offline'
    task import: :environment do
      require 'net/http'
      require 'gitlab/json'

      spdx_url = ::Gitlab::SPDX::CatalogueGateway::URL
      resp = Gitlab::HTTP.get(URI.parse(spdx_url))

      raise 'Network failure' if resp.code != 200

      data = ::Gitlab::Json.parse(resp.body)

      path = ::Gitlab::SPDX::CatalogueGateway::OFFLINE_CATALOGUE
      File.write(path, data.to_json, mode: 'w')

      puts "Local copy of SPDX catalogue is saved to #{path}"
    rescue StandardError => e
      puts "Import of SPDX catalogue failed: #{e}"
    end
  end
end
