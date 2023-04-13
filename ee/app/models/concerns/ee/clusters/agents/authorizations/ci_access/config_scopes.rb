# frozen_string_literal: true

module EE
  module Clusters
    module Agents
      module Authorizations
        module CiAccess
          module ConfigScopes
            extend ActiveSupport::Concern

            prepended do
              class_methods do
                alias_method :base_available_ci_access_fields, :available_ci_access_fields

                def available_ci_access_fields(project)
                  base_available_ci_access_fields(project).tap do |fields|
                    if project.licensed_feature_available?(:cluster_agents_ci_impersonation)
                      fields << "ci_job"
                      fields << "ci_user"
                      fields << "impersonate"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
