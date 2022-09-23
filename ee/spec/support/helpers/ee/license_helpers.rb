# frozen_string_literal: true

module EE
  module LicenseHelpers
    extend ActiveSupport::Concern

    # Enable/Disable a feature on the License for a spec.
    #
    # Example:
    #
    #   stub_licensed_features(geo: true, file_locks: false)
    #
    # This enables `geo` and disables `file_locks` features for a spec.
    # Other features are still enabled/disabled as defined in the license.

    prepended do
      def stub_licensed_features(features)
        missing_features = features.keys.map(&:to_sym) - GitlabSubscriptions::Features::ALL_FEATURES

        if missing_features.any?
          subject = missing_features.join(', ')
          noun = 'feature'.pluralize(missing_features.size)
          raise ArgumentError, "#{subject} should be defined as licensed #{noun}"
        end

        allow(License).to receive(:feature_available?).and_call_original

        features.each do |feature, enabled|
          allow(License).to receive(:feature_available?).with(feature) { enabled }
        end
      end

      # Do not clear license feature cache in this block.
      #
      # Useful for specs which rely on caching license features.
      def with_license_feature_cache(&block)
        ClearLicensedFeatureAvailableCache.without_clear_cache(&block)
      end

      def enable_namespace_license_check!
        stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
        ::Gitlab::CurrentSettings.update!(check_namespace_plan: true)
      end

      def create_current_license(gitlab_license_options = {}, license_options = {})
        License.current&.destroy!

        gl_license = create(:gitlab_license, gitlab_license_options)

        create(:license, license_options.merge(data: gl_license.export))
      end

      def create_current_license_without_expiration(gitlab_license_options = {}, license_options = {})
        gitlab_license_options[:licensee] = {
          'Name' => 'Team Member',
          'Email' => 'team_member@gitlab.com',
          'Company' => 'GitLab'
        }
        gitlab_license_options[:expires_at] = nil

        create_current_license(gitlab_license_options, license_options)
      end

      ::Project.prepend ClearLicensedFeatureAvailableCache
      ::Namespace.prepend ClearLicensedFeatureAvailableCache
    end

    # This patch helps `stub_licensed_features` to work properly
    # without the need of clearing caches manually in `before` blocks or
    # using `let_it_be_refind` deliberately.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/10385
    module ClearLicensedFeatureAvailableCache
      class << self
        attr_accessor :clear_cache

        def without_clear_cache
          self.clear_cache = false
          yield
        ensure
          self.clear_cache = true
        end
      end

      # Enabled by default but can be disabled via `without_clear_cache`.
      self.clear_cache = true

      def licensed_feature_available?(*)
        clear_memoization(:licensed_feature_available) if ClearLicensedFeatureAvailableCache.clear_cache

        super
      end
    end
  end
end
