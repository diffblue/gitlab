# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module CiCd
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                include Page::Component::SecureReport

                view 'ee/app/views/projects/settings/ci_cd/_pipeline_subscriptions.html.haml' do
                  element :pipeline_subscriptions_setting_content
                end
              end
            end

            def expand_pipeline_subscriptions(&block)
              expand_content(:pipeline_subscriptions_setting_content) do
                Settings::PipelineSubscriptions.perform(&block)
              end
            end
          end
        end
      end
    end
  end
end
