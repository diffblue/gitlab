# frozen_string_literal: true

module Security
  class DependencyListService
    SORT_BY_VALUES = %w(name packager severity).freeze
    SORT_VALUES = %w(asc desc).freeze
    FILTER_PACKAGE_MANAGERS_VALUES = %w(bundler yarn npm pnpm maven composer pip conan go nuget sbt gradle pipenv setuptools).freeze
    FILTER_VALUES = %w(all vulnerable).freeze

    # @param pipeline [Ci::Pipeline]
    # @param [Hash] params to sort and filter dependencies
    # @option params ['asc', 'desc'] :sort ('asc') Order
    # @option params ['name', 'packager', 'severity'] :sort_by ('name') Field to sort
    # @option params ['bundler', 'yarn', 'npm', 'maven', 'composer', 'pip', 'conan', 'go', 'nuget', 'sbt', 'gradle', 'pipenv', 'setuptools'] :package_manager ('bundler') Field to filter
    # @option params ['all', 'vulnerable'] :filter ('all') Field to filter
    def initialize(pipeline:, params: {})
      @pipeline = pipeline
      @params = params
    end

    # @return [Array<Hash>] collection of found dependencies
    def execute
      collection = init_collection
      collection = filter_by_package_manager(collection)
      collection = filter_by_vulnerable(collection)
      sort(collection)
    end

    private

    attr_accessor :params, :pipeline

    def init_collection
      pipeline.dependency_list_report.dependencies
    end

    def filter_by_package_manager(collection)
      return collection unless params[:package_manager]

      # ensure that package_manager is an Array
      # otherwise #include? is true when dependency[:package_manager]
      # begins with params[:package_manager] (String),
      # even if the requested package manager isn't a match
      package_managers = params[:package_manager]
      package_managers = [package_managers] unless params[:package_manager].is_a?(Array)

      collection.select do |dependency|
        package_managers.include?(dependency[:package_manager])
      end
    end

    def filter_by_vulnerable(collection)
      return collection unless params[:filter] == 'vulnerable'

      collection.select do |dependency|
        dependency[:vulnerabilities].any?
      end
    end

    def sort(collection)
      default_sort_order = 'asc'

      case params[:sort_by]
      when 'packager'
        collection.sort_by! { |a| a[:packager] }
      when 'severity'
        default_sort_order = 'desc'
        sort_dependency_vulnerabilities_by_severity!(collection)
        sort_dependencies_by_severity!(collection)
      else
        collection.sort_by! { |a| a[:name] }
      end

      if params[:sort] && params[:sort] != default_sort_order
        collection.reverse!
      end

      collection
    end

    def compare_severity_levels(level1, level2)
      # level2 appears before level1 because we want the default sort order to be in descending
      # order of severity level, for example "critical, high, medium, low"
      ::Enums::Vulnerability.severity_levels[level2] <=> ::Enums::Vulnerability.severity_levels[level1]
    end

    # sort dependency vulnerabilities in descending order by severity level
    def sort_dependency_vulnerabilities_by_severity!(collection)
      collection.each do |dependency|
        dependency[:vulnerabilities].sort! do |vulnerability1, vulnerability2|
          compare_severity_levels(vulnerability1[:severity], vulnerability2[:severity])
        end
      end
    end

    # vulnerabilities are already sorted in descending order by severity level so we can assume that
    # first vulnerability in the vulnerabilities array will have the highest severity
    def sort_dependencies_by_severity!(collection)
      collection.sort! do |dep_i, dep_j|
        level_i = dep_i.dig(:vulnerabilities, 0, :severity) || :info
        level_j = dep_j.dig(:vulnerabilities, 0, :severity) || :info
        compare_severity_levels(level_i, level_j)
      end
    end
  end
end
