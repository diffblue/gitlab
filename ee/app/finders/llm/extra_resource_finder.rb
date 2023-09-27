# frozen_string_literal: true

module Llm
  # ExtraResourceFinder attempts to locate a resource based on `referer_url`
  # Presently, the finder only deals with a Blob resource.
  # Since the finder does not deal with DB resources, it's been added to spec/support/finder_collection_allowlist.yml.
  # As more resource types need to be supported (potentially), appropriate abstractions should be designed and added.
  class ExtraResourceFinder
    def initialize(current_user, referer_url)
      @current_user = current_user
      @referer_url = referer_url
      @extra_resources = {}
    end

    def execute
      find_blob_resource

      @extra_resources
    end

    private

    def find_blob_resource
      return unless @referer_url

      project_fullpath, resource_path = parse_referer(@referer_url)
      return unless project_fullpath && resource_path

      @project = find_project(project_fullpath)
      return unless @project

      ref, path = extract_blob_ref_and_path(resource_path)
      return unless ref && path

      blob = find_blob(ref, path)

      @extra_resources[:blob] = blob if blob && blob.readable_text?
    end

    def find_project(project_fullpath)
      project = Project.find_by_full_path(project_fullpath)
      return unless project && @current_user.can?(:read_code, project) && project.repository

      project
    end

    def find_blob(ref, path)
      commit = @project.repository.commit(ref)
      return if commit.nil?

      @project.repository.blob_at(commit.id, path)
    end

    def parse_referer(referer_url)
      referer_url.split("#{Gitlab.config.gitlab.base_url}/")[1].try(:split, "/-/", 2)
    end

    def extract_blob_ref_and_path(resource_path)
      return unless resource_path.start_with?("blob/")

      resource_path = resource_path
                        .sub('blob/', '') # Trim `blob/`
                        .split(%r{\#|\?}, 2) # Extract up to the first occurence of # or ? (URL anchor/param)
                        .first.tap { |blob_path| blob_path || "" }
      return if resource_path.empty?

      ExtractsRef::RefExtractor.new(@project, {}).extract_ref(resource_path)
    end
  end
end
