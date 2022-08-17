# frozen_string_literal: true

module AppSec
  module Dast
    module Profiles
      class CreateAssociationsService < BaseProjectService
        include ::Gitlab::Ci::Pipeline::Chain::Helpers

        def execute
          return ServiceResponse.error(message: _('Insufficient permissions for dast_configuration keyword')) unless allowed?

          dast_site_profiles = find_dast_site_profiles
          dast_scanner_profiles = find_dast_scanner_profiles

          dast_site_profiles_builds, dast_scanner_profiles_builds = prepare_batch_inserts(dast_scanner_profiles, dast_site_profiles)

          return ServiceResponse.error(message: errors) unless errors.empty?

          insert_builds(dast_site_profiles_builds, dast_scanner_profiles_builds)

          ServiceResponse.success
        end

        private

        def allowed?
          can?(current_user, :create_on_demand_dast_scan, project)
        end

        def has_permission?(profile, name)
          if can?(current_user, :read_on_demand_dast_scan, profile)
            true
          else
            errors.push(_('DAST profile not found: %{name}') % { name: name })
            false
          end
        end

        def builds
          @builds ||= params[:builds] || []
        end

        def errors
          @errors ||= []
        end

        def prepare_batch_inserts(dast_scanner_profiles, dast_site_profiles)
          dast_site_profiles_builds = []
          dast_scanner_profiles_builds = []

          builds.each do |build|
            next unless build.is_a?(::Ci::Build)

            if (site_profile_name = build.options.dig(:dast_configuration, :site_profile))
              dast_site_profile = dast_site_profiles.find { |dsp| dsp.name == site_profile_name }

              dast_site_profiles_builds.append({ ci_build_id: build.id, dast_site_profile_id: dast_site_profile.id }) if has_permission?(dast_site_profile, site_profile_name)
            end

            scanner_profile_name = build.options.dig(:dast_configuration, :scanner_profile)
            next unless scanner_profile_name

            dast_scanner_profile = dast_scanner_profiles.find { |dsp| dsp.name == scanner_profile_name }

            dast_scanner_profiles_builds.append({ ci_build_id: build.id, dast_scanner_profile_id: dast_scanner_profile.id }) if has_permission?(dast_scanner_profile, scanner_profile_name)
          end

          [dast_site_profiles_builds, dast_scanner_profiles_builds]
        end

        def find(key, with:)
          names = builds.map { |build| build.options.dig(:dast_configuration, key) }.compact

          with.new(project_id: project.id, name: names).execute
        end

        def find_dast_site_profiles
          find(:site_profile, with: DastSiteProfilesFinder)
        end

        def find_dast_scanner_profiles
          find(:scanner_profile, with: DastScannerProfilesFinder)
        end

        def insert_builds(dast_site_profiles_builds, dast_scanner_profiles_builds)
          ::Dast::SiteProfilesBuild.insert_all(dast_site_profiles_builds, unique_by: 'ci_build_id') unless dast_site_profiles_builds.empty?
          ::Dast::ScannerProfilesBuild.insert_all(dast_scanner_profiles_builds, unique_by: 'ci_build_id') unless dast_scanner_profiles_builds.empty?
        end
      end
    end
  end
end
