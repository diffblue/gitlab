# frozen_string_literal: true

module QA
  module EE
    module Resource
      class PipelineSubscriptions < QA::Resource::Base
        attr_accessor :project_path

        def fabricate!
          QA::Page::Project::Menu.perform(&:go_to_ci_cd_settings)

          QA::Page::Project::Settings::CiCd.perform do |setting|
            setting.expand_pipeline_subscriptions do |page|
              page.subscribe(project_path)
            end
          end
        end
      end
    end
  end
end
