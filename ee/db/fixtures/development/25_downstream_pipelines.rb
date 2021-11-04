# frozen_string_literal: true
# EE fixture
Gitlab::Seeder.quiet do
  Project.not_mass_generated.sample(5).each do |project|
    project.builds.sample(2).each do |build|
      pipeline = build.pipeline
      next if pipeline.source_pipeline

      target_pipeline = Ci::Pipeline
        .where.not(project: project)
        .order('random()').first

      # If the number of created projects is 1 (i.e. env['SIZE'] == 1),
      # a target pipeline becomes nil.
      next unless target_pipeline

      # link to source pipeline
      pipeline.sourced_pipelines.create!(
        source_job: pipeline.builds.sample,
        source_project: pipeline.project,
        project: target_pipeline.project,
        pipeline: target_pipeline
      )
    end
  end
end
