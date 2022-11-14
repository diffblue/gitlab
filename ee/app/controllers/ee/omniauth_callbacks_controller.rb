# frozen_string_literal: true

module EE
  module OmniauthCallbacksController
    extend ::Gitlab::Utils::Override

    private

    override :after_sign_in_path_for
    def after_sign_in_path_for(resource)
      path = super

      geo_site = sign_in_via_geo_proxied_site
      if geo_site
        url = [geo_site.url, path.delete_prefix("/")].join

        log_message = "User signed in via a Geo proxy site with a separate URL, so redirect to the proxy URL"
        ::Gitlab::AppJsonLogger.debug(
          message: log_message,
          "#{::Gitlab::Geo::SIGN_IN_VIA_GEO_SITE_ID}": geo_site.id,
          geo_site_url: geo_site.url
        )

        return url
      end

      path
    end

    def sign_in_via_geo_proxied_site
      return unless ::Gitlab::Geo.enabled?
      return unless ::Feature.enabled?(:geo_fix_redirect_after_saml_sign_in)

      geo_site_id ||= session.delete(::Gitlab::Geo::SIGN_IN_VIA_GEO_SITE_ID)
      return unless geo_site_id.present?

      ::GeoNode.find_by_id(geo_site_id)
    end

    override :log_failed_login
    def log_failed_login(author, provider)
      ::AuditEventService.new(
        author,
        nil,
        with: provider
      ).for_failed_login.unauth_security_event
    end
  end
end
