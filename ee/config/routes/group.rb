# frozen_string_literal: true

constraints(::Constraints::GroupUrlConstrainer.new) do
  scope(
    path: 'groups/*group_id/-',
    module: :groups,
    as: :group,
    constraints: { group_id: Gitlab::PathRegex.full_namespace_route_regex }
  ) do
    draw :wiki

    namespace :settings do
      resource :reporting, only: [:show], controller: 'reporting'
      resources :domain_verification, only: [:index, :new, :create, :show, :update, :destroy], constraints: { id: %r{[^/]+} } do
        member do
          post :verify
          post :retry_auto_ssl
          delete :clean_certificate
        end
      end
      resource :merge_requests, only: [:update]
    end

    resources :group_members, only: [], concerns: :access_requestable do
      patch :override, on: :member
      put :unban, on: :member
      put :ban, on: :member

      collection do
        get :export_csv
      end
    end

    resource :two_factor_auth, only: [:destroy]

    get '/analytics', to: redirect('groups/%{group_id}/-/analytics/value_stream_analytics')
    resource :contribution_analytics, only: [:show]

    namespace :analytics do
      resource :ci_cd_analytics, only: :show, path: 'ci_cd'
      resources :dashboards, only: :index do
        collection do
          get :value_streams_dashboard
        end
      end
      resource :devops_adoption, controller: :devops_adoption, only: :show
      resource :productivity_analytics, only: :show
      resources :coverage_reports, only: :index
      resource :merge_request_analytics, only: :show
      resource :repository_analytics, only: :show
      resource :cycle_analytics, only: :show, path: 'value_stream_analytics'
      scope module: :cycle_analytics, as: 'cycle_analytics', path: 'value_stream_analytics' do
        resources :value_streams do
          resources :stages, only: [:index] do
            member do
              get :average_duration_chart
              get :median
              get :average
              get :records
              get :count
            end
          end
        end
        resource :summary, controller: :summary, only: :show
        get '/time_summary' => 'summary#time_summary'
        get '/lead_times' => 'summary#lead_times'
        get '/cycle_times' => 'summary#cycle_times'
      end
      get '/cycle_analytics', to: redirect('-/analytics/value_stream_analytics')

      scope :type_of_work do
        resource :tasks_by_type, controller: :tasks_by_type, only: :show do
          get :top_labels
        end
      end
    end

    resource :ldap, only: [] do
      member do
        put :sync
      end
    end

    resource :ldap_settings, only: [:update]

    resource :issues_analytics, only: [:show]

    resource :insights, only: [:show], defaults: { trailing_slash: true } do
      collection do
        post :query
      end
    end

    resource :notification_setting, only: [:update]

    resources :ldap_group_links, only: [:index, :create, :destroy]
    resources :saml_group_links, only: [:index, :create, :destroy]
    resources :audit_events, only: [:index]
    resources :usage_quotas, only: [:index] do
      collection do
        get :pending_members
      end
    end

    resources :hooks, only: [:index, :create, :edit, :update, :destroy], constraints: { id: /\d+/ } do
      member do
        post :test
      end

      resources :hook_logs, only: [:show] do
        member do
          post :retry
        end
      end
    end

    resources :autocomplete_sources, only: [] do
      collection do
        get 'epics'
        get 'iterations'
        get 'vulnerabilities'
      end
    end

    resources :billings, only: [:index] do
      collection do
        post :refresh_seats
      end
    end

    get :seat_usage, to: 'seat_usage#show'

    resources :epics, concerns: :awardable, constraints: { id: /\d+/ } do
      member do
        get '/descriptions/:version_id/diff', action: :description_diff, as: :description_diff
        delete '/descriptions/:version_id', action: :delete_description_version, as: :delete_description_version
        get :discussions, format: :json
        get :realtime_changes
        post :toggle_subscription
      end

      resources :epic_issues, only: [:index, :create, :destroy, :update], as: 'issues', path: 'issues'

      scope module: :epics do
        resources :notes, only: [:index, :create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ }
        resources :epic_links, only: [:index, :create, :destroy, :update], as: 'links', path: 'links'
        resources :related_epic_links, only: [:index, :create, :destroy]
      end

      collection do
        post :bulk_update
      end
    end

    resources :iterations, only: [:index, :new, :edit, :show], constraints: { id: /\d+/ }

    resources :iteration_cadences, path: 'cadences(/*vueroute)', action: :index do
      resources :iterations, only: [:index, :new, :edit, :show], constraints: { id: /\d+/ }, controller: :iteration_cadences, action: :index
    end

    resources :issues, only: [] do
      collection do
        post :bulk_update
      end
    end

    resources :merge_requests, only: [] do
      collection do
        post :bulk_update
      end
    end

    resources :todos, only: [:create]

    resources :epic_boards, only: [:index, :show]
    resources :protected_environments, only: [:create, :update, :destroy]

    namespace :security do
      resource :dashboard, only: [:show], controller: :dashboard
      resources :vulnerabilities, only: [:index]
      resource :compliance_dashboard, path: 'compliance_dashboard(/*vueroute)', only: [:show]
      resource :discover, only: [:show], controller: :discover
      resources :credentials, only: [:index, :destroy] do
        member do
          put :revoke
        end
      end
      resources :policies, only: [:index, :new, :edit], constraints: { id: %r{[^/]+} } do
        collection do
          get :schema
        end
      end

      resources :merge_commit_reports, only: [:index], constraints: { format: :csv }
      resources :compliance_framework_reports, only: [:index], constraints: { format: :csv }
    end

    resource :push_rules, only: [:update]

    resources :protected_branches, only: [:create, :update, :destroy]

    resource :saml_providers, path: 'saml', only: [:show, :create, :update] do
      callback_methods = Rails.env.test? ? [:get, :post] : [:post]
      match :callback, to: 'omniauth_callbacks#group_saml', via: callback_methods
      get :sso, to: 'sso#saml'
      delete :unlink, to: 'sso#unlink'
    end

    resource :scim_oauth, only: [:create], controller: :scim_oauth

    get :sign_up, to: 'sso#sign_up_form'
    post :sign_up, to: 'sso#sign_up'
    post :authorize_managed_account, to: 'sso#authorize_managed_account'

    resource :roadmap, only: [:show], controller: 'roadmap'

    post '/restore' => '/groups#restore', as: :restore
  end
end
