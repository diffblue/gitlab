# frozen_string_literal: true

class ReportListEntity < Grape::Entity
  include RequestAwareEntity

  expose :report do
    expose :status do |list, options|
      status(list[items_name], options[:build])
    end

    expose :job_path, if: ->(_, options) { options[:build] && can_read_job_path? } do |_, options|
      project_build_path(project, options[:build].id)
    end

    expose :generated_at, if: ->(_, options) { options[:build] && can_read_job_path? } do |_, options|
      options[:build].finished_at
    end
  end

  private

  def can_read_job_path?
    can?(request.user, :read_pipeline, project)
  end

  def items_name
    raise NotImplementedError
  end

  def project
    request.project
  end

  def status(dependencies, build)
    if build&.success? || project.nil?
      if dependencies.any?
        :ok
      else
        "no_#{items_name}".to_sym
      end
    elsif build&.failed?
      :job_failed
    else
      :job_not_set_up
    end
  end
end
