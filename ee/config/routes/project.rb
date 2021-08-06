# frozen_string_literal: true

constraints(::Constraints::ProjectUrlConstrainer.new) do
  scope(path: '*namespace_id',
        as: :namespace,
        namespace_id: Gitlab::PathRegex.full_namespace_route_regex) do
    scope(path: ':project_id',
          constraints: { project_id: Gitlab::PathRegex.project_route_regex },
          module: :projects,
          as: :project) do
      # Begin of the /-/ scope.
      # Use this scope for all new project routes.
      scope '-' do
        namespace :requirements_management do
          resources :requirements, only: [:index] do
            collection do
              post :import_csv
              post 'import_csv/authorize', to: 'requirements#authorize'
            end
          end
        end

        namespace :quality do
          resources :test_cases, only: [:index, :new, :show]
        end

        resources :autocomplete_sources, only: [] do
          collection do
            get 'epics'
            get 'vulnerabilities'
          end
        end

        namespace :settings do
          resource :slack, only: [:destroy, :edit, :update] do
            get :slack_auth
          end
        end

        resources :subscriptions, only: [:create, :destroy]

        resource :threat_monitoring, only: [:show], controller: :threat_monitoring do
          get '/alerts/:iid', action: 'alert_details', constraints: { iid: /\d+/ }, as: :threat_monitoring_alert
          resources :policies, only: [:new, :edit], controller: :threat_monitoring, constraints: { id: %r{[^/]+} }
        end

        resources :protected_environments, only: [:create, :update, :destroy], constraints: { id: /\d+/ } do
          collection do
            get 'search'
          end
        end

        resources :audit_events, only: [:index]

        namespace :security do
          resources :network_policies, only: [:index, :create, :update, :destroy], constraints: { id: %r{[^/]+} } do
            get :summary, on: :collection
          end

          resources :dashboard, only: [:index], controller: :dashboard
          resources :vulnerability_report, only: [:index], controller: :vulnerability_report

          resource :policy, only: [:show]

          resources :policies, only: [:edit], controller: :policies, constraints: { id: %r{[^/]+} }

          resource :configuration, only: [], controller: :configuration do
            post :auto_fix, on: :collection
            resource :corpus_management, only: [:show], controller: :corpus_management
            resource :sast, only: [:show], controller: :sast_configuration
            resource :api_fuzzing, only: :show, controller: :api_fuzzing_configuration
            resource :dast_scans, only: [:show], controller: :dast_profiles do
              resources :dast_site_profiles, only: [:new, :edit]
              resources :dast_scanner_profiles, only: [:new, :edit]
            end
            resource :dast, only: :show, controller: :dast_configuration
          end

          resource :discover, only: [:show], controller: :discover

          resources :scanned_resources, only: [:index]

          resources :vulnerabilities, only: [:show] do
            member do
              get :discussions, format: :json
            end

            scope module: :vulnerabilities do
              resources :notes, only: [:index, :create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ }
            end
          end
        end

        namespace :analytics do
          resources :code_reviews, only: [:index]
          resource :issues_analytics, only: [:show]
          resource :merge_request_analytics, only: :show

          scope module: :cycle_analytics, as: 'cycle_analytics', path: 'value_stream_analytics' do
            get '/time_summary' => 'summary#time_summary'
          end
        end

        resources :approvers, only: :destroy
        resources :approver_groups, only: :destroy
        resources :push_rules, constraints: { id: /\d+/ }, only: [:update]
        resources :vulnerability_feedback, only: [:index, :create, :update, :destroy], constraints: { id: /\d+/ }
        resources :dependencies, only: [:index]
        resources :licenses, only: [:index, :create, :update]

        resources :feature_flags, param: :iid do
          resources :feature_flag_issues, only: [:index, :create, :destroy], as: 'issues', path: 'issues'
        end

        resources :on_demand_scans, only: [:index, :new, :edit]

        namespace :integrations do
          namespace :jira do
            resources :issues, only: [:index, :show] do
              member do
                get :labels
              end
            end
          end
        end

        # Added for backward compatibility with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39543
        # TODO: Cleanup https://gitlab.com/gitlab-org/gitlab/-/issues/320814
        get 'iterations/inherited/:id', to: redirect('%{namespace_id}/%{project_id}/-/iterations/%{id}'),
            as: :legacy_project_iterations_inherited

        resources :iterations, only: [:index, :show], constraints: { id: /\d+/ }

        resources :iteration_cadences, path: 'cadences(/*vueroute)', action: :index do
          resources :iterations, only: [:index, :show], constraints: { id: /\d+/ }, controller: :iteration_cadences, action: :index
        end

        namespace :incident_management, path: '' do
          resources :oncall_schedules, only: [:index], path: 'oncall_schedules'
          resources :escalation_policies, only: [:index], path: 'escalation_policies'
        end

        resources :cluster_agents, only: [:show], param: :name
      end
      # End of the /-/ scope.

      # All new routes should go under /-/ scope.
      # Look for scope '-' at the top of the file.
      # rubocop: disable Cop/PutProjectRoutesUnderScope

      resources :path_locks, only: [:index, :destroy] do
        collection do
          post :toggle
        end
      end

      post '/restore' => '/projects#restore', as: :restore

      resource :insights, only: [:show], trailing_slash: true do
        collection do
          post :query
        end
      end
      # All new routes should go under /-/ scope.
      # Look for scope '-' at the top of the file.
      # rubocop: enable Cop/PutProjectRoutesUnderScope
    end
  end
end
