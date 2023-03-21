# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module DependencyList
        class Report
          # Stores dependency_path info in Hash of Hashes
          # where keys of external Hash are path to dependency files
          # and keys of internal Hashes are iid of dependencies
          attr_reader :dependency_map

          def initialize
            @dependencies = {}
            @dependency_map = {}
          end

          def dependencies
            augment_ancestors!
            @dependencies.values.map(&:to_hash)
          end

          def add_dependency(dependency)
            dep = Dependency.new(dependency)
            key = dep.composite_key

            store_dependency_path_info(dep) if dep.iid

            if @dependencies.has_key?(key)
              existing_dependency = @dependencies[key]
              existing_dependency.update_dependency(dependency)
            else
              @dependencies[key] = dep
            end
          end

          def apply_license(license)
            dependencies.each do |dependency|
              next unless license_includes_dependency(license, dependency)
              next if dependency[:licenses].find { |license_hash| license_hash[:name] == license.name }

              dependency[:licenses].push(name: license.name, url: license.url)
            end
          end

          def dependencies_with_licenses
            dependencies.select { |dependency| dependency[:licenses].any? }
          end

          private

          def license_includes_dependency(license, dependency)
            license.dependencies.find do |license_dependency|
              dependency_name = ::Sbom::PackageUrl::Normalizer.new(type: license_dependency.purl_type, text: dependency[:name]).normalize_name

              license_dependency.name == dependency_name
            end
          end

          def augment_ancestors!
            @dependencies.each_value do |dep|
              next unless dep.location[:ancestors]
              next if dep.location[:top_level]

              if dep.vulnerabilities.empty?
                dep.location.except!(:ancestors)
              else
                dependency_file = dep.location[:path]
                dependencies_by_iid = dependency_map[dependency_file]

                dep.location[:ancestors].map! do |ancestor|
                  next ancestor unless ancestor.fetch(:iid, false)

                  dependencies_by_iid[ancestor[:iid]]
                end
              end
            end
          end

          def store_dependency_path_info(dependency)
            dependency_file = dependency.location[:path]

            dependency_map[dependency_file] ||= {}

            dependency_map[dependency_file][dependency.iid] = { name: dependency.name, version: dependency.version }
          end
        end
      end
    end
  end
end
