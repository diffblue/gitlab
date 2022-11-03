# frozen_string_literal: true

module Sitemap
  class CreateService
    def execute
      result = Gitlab::Sitemaps::Generator.execute

      if result.is_a?(String)
        error_response(result)
      else
        success_response(result)
      end
    end

    private

    def success_response(file)
      Gitlab::AppLogger.info("Sitemap generated successfully")

      ServiceResponse.success(payload: { sitemap: file.render })
    end

    def error_response(message)
      Gitlab::AppLogger.error("Sitemap error creating sitemap: #{message}")

      ServiceResponse.error(
        message: message
      )
    end
  end
end
