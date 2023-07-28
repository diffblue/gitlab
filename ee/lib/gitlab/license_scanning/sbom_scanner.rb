# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class SbomScanner < ::Gitlab::LicenseScanning::BaseScanner
      include Gitlab::Utils::StrongMemoize

      def self.latest_pipeline(project, ref)
        project.latest_pipeline_with_reports_for_ref(ref, ::Ci::JobArtifact.of_report_type(:sbom))
      end

      def report
        return empty_report if pipeline.blank?

        components = PipelineComponents.new(pipeline: pipeline).fetch
        package_licenses = PackageLicenses.new(project: project, components: components).fetch

        ::Gitlab::Ci::Reports::LicenseScanning::Report.new.tap do |license_scanning_report|
          package_licenses.each do |package_license|
            package_license.licenses.each do |license_hash|
              license = license_scanning_report.add_license(
                id: license_hash["spdx_identifier"], name: license_hash["name"])

              license.add_dependency(
                name: package_license.name,
                package_manager: package_license.package_manager,
                purl_type: package_license.purl_type,
                version: package_license.version
              )
            end
          end
        end
      end

      def has_data?
        return false if pipeline.blank?

        pipeline.has_reports?(::Ci::JobArtifact.of_report_type(:sbom))
      end

      def results_available?
        return false if pipeline.blank?

        pipeline.complete_and_has_reports?(::Ci::JobArtifact.of_report_type(:sbom))
      end

      def latest_build_for_default_branch
        pipeline = self.class.latest_pipeline(project, project.default_branch)

        return if pipeline.blank?

        pipeline.builds.latest.sbom_generation.last
      end
      strong_memoize_attr :latest_build_for_default_branch

      # dependencies is an array of dependency objects which come from the dependency_files section
      # of the dependency scanning report. These entries do not include license information. For example:
      # [
      #   {
      #     :name=>"Django", :packager=>"Python (pip)", :package_manager=>"pip",
      #     :version=>"1.11.4", :licenses=>[], :vulnerabilities=>[],
      #     :location=> { :blob_path=>"/some/path", :path=>"requirements.txt" }
      #   },
      #   {
      #     :name=>"actioncable", :packager=>"Ruby (Bundler)", :package_manager=>"bundler",
      #     :version=>"5.0.0", :licenses=>[], :vulnerabilities=>[]
      #     :location=> { :blob_path=>"/some/path", :path=>"Gemfile.lock" }
      #   }
      # ]
      #
      # components is an array of Hashie::Mash items which contain purl_type, name, and version fields
      # For example:
      # [
      #   { name: "django", purl_type: "pypi",  version: "1.11.4" },
      #   { name: "actioncable", purl_type: "gem", version: "5.0.0" },
      #   { name: "actionmailer",  purl_type: "gem", version: "5.0.0" }
      # ]
      #
      # this method obtains the licenses for each of the entries in the components array, then
      # adds them to the licenses field of each dependency
      def add_licenses(dependencies)
        package_licenses = PackageLicenses.new(project: project, components: build_components(dependencies)).fetch

        dependencies.each_with_index do |dependency, idx|
          dependency[:licenses] = package_licenses[idx].licenses.map do |license|
            {
              name: license.name,
              url: ::Gitlab::Ci::Reports::LicenseScanning::License.spdx_url(license.spdx_identifier)
            }
          end
        end
      end

      private

      def build_components(dependencies)
        dependencies.map do |dependency|
          purl_type = ::Sbom::PurlType::Converter.purl_type_for_pkg_manager(dependency[:package_manager])

          Hashie::Mash.new(
            name: ::Sbom::PackageUrl::Normalizer.new(type: purl_type, text: dependency[:name]).normalize_name,
            purl_type: purl_type,
            version: dependency[:version])
        end
      end
    end
  end
end
