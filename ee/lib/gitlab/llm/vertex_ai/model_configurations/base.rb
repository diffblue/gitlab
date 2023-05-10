# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ModelConfigurations
        class Base
          def url
            raise NotImplementedError
          end

          def host
            raise NotImplementedError
          end

          private

          delegate :tofa_url, :tofa_host, to: :settings

          def settings
            @settings ||= Gitlab::CurrentSettings.current_application_settings
          end
        end
      end
    end
  end
end
