# frozen_string_literal: true

module QA
  ##
  # GitLab EE extensions
  #
  module EE
    module Runtime
      autoload :Env, 'qa/ee/runtime/env'
      autoload :Geo, 'qa/ee/runtime/geo'
      autoload :Saml, 'qa/ee/runtime/saml'
    end

    module Page
      autoload :OperationsDashboard, 'qa/ee/page/operations_dashboard'

      module Component
        autoload :LicenseManagement, 'qa/ee/page/component/license_management'
        autoload :SecureReport, 'qa/ee/page/component/secure_report'

        module IssueBoard
          autoload :Show, 'qa/ee/page/component/issue_board/show'
        end

        module WebIDE
          autoload :WebTerminalPanel, 'qa/ee/page/component/web_ide/web_terminal_panel'
        end
      end

      module Dashboard
        autoload :Projects, 'qa/ee/page/dashboard/projects'
      end

      module Group
        autoload :Menu, 'qa/ee/page/group/menu'
        autoload :SamlSSOSignIn, 'qa/ee/page/group/saml_sso_sign_in'
        autoload :SamlSSOSignUp, 'qa/ee/page/group/saml_sso_sign_up'
        autoload :Members, 'qa/ee/page/group/members'
        autoload :ContributionAnalytics, 'qa/ee/page/group/contribution_analytics'

        module Iteration
          autoload :Index, 'qa/ee/page/group/iteration/index'
          autoload :New, 'qa/ee/page/group/iteration/new'
          autoload :Show, 'qa/ee/page/group/iteration/show'
        end

        module Settings
          autoload :SamlSSO, 'qa/ee/page/group/settings/saml_sso'
          autoload :LDAPSync, 'qa/ee/page/group/settings/ldap_sync'
          autoload :General, 'qa/ee/page/group/settings/general'
        end

        module Wiki
          autoload :Show, 'qa/ee/page/group/wiki/show'
          autoload :Edit, 'qa/ee/page/group/wiki/edit'
        end
      end

      module File
        autoload :Show, 'qa/ee/page/file/show'
      end

      module Main
        autoload :Banner, 'qa/ee/page/main/banner'
      end

      module Registration
        autoload :Welcome, 'qa/ee/page/registration/welcome'
      end

      module Admin
        autoload :Menu, 'qa/ee/page/admin/menu'
        autoload :License, 'qa/ee/page/admin/license'

        module Geo
          module Nodes
            autoload :Show, 'qa/ee/page/admin/geo/nodes/show'
            autoload :New, 'qa/ee/page/admin/geo/nodes/new'
          end
        end

        module Monitoring
          autoload :AuditLog, 'qa/ee/page/admin/monitoring/audit_log.rb'
        end

        module Settings
          autoload :Templates, 'qa/ee/page/admin/settings/templates'
          autoload :Preferences, 'qa/ee/page/admin/settings/preferences'

          module Component
            autoload :Email, 'qa/ee/page/admin/settings/component/email'
            autoload :Elasticsearch, 'qa/ee/page/admin/settings/component/elasticsearch'
          end
        end

        module Overview
          module Groups
            autoload :Edit, 'qa/ee/page/admin/overview/groups/edit'
          end
        end
      end

      module Milestone
        autoload :Show, 'qa/ee/page/milestone/show'
      end

      module Profile
        autoload :Menu, 'qa/ee/page/profile/menu'
      end

      module Project
        autoload :New, 'qa/ee/page/project/new'
        autoload :Show, 'qa/ee/page/project/show'
        autoload :Menu, 'qa/ee/page/project/menu'

        module SubMenus
          autoload :SecurityCompliance, 'qa/ee/page/project/sub_menus/security_compliance'
          autoload :Repository, 'qa/ee/page/project/sub_menus/repository'
          autoload :Settings, 'qa/ee/page/project/sub_menus/settings'
          autoload :Analytics, 'qa/ee/page/project/sub_menus/analytics'
          autoload :LicenseCompliance, 'qa/ee/page/project/sub_menus/license_compliance'
        end

        module Issue
          autoload :Index, 'qa/ee/page/project/issue/index'
          autoload :Show, 'qa/ee/page/project/issue/show'
        end

        module Wiki
          autoload :Show, 'qa/ee/page/project/wiki/show'
        end

        module Settings
          autoload :ProtectedBranches, 'qa/ee/page/project/settings/protected_branches'
          autoload :Main, 'qa/ee/page/project/settings/main'
          autoload :MirroringRepositories, 'qa/ee/page/project/settings/mirroring_repositories'
          autoload :ProtectedTags, 'qa/ee/page/project/settings/protected_tags'
          autoload :MergeRequest, 'qa/ee/page/project/settings/merge_request'
          autoload :MergeRequestApprovals, 'qa/ee/page/project/settings/merge_request_approvals'
          autoload :Integrations, 'qa/ee/page/project/settings/integrations'
          autoload :Repository, 'qa/ee/page/project/settings/repository'
          autoload :PushRules, 'qa/ee/page/project/settings/push_rules'
          autoload :IssueTemplateDefault, 'qa/ee/page/project/settings/issue_template_default.rb'
          autoload :CICD, 'qa/ee/page/project/settings/ci_cd'
          autoload :PipelineSubscriptions, 'qa/ee/page/project/settings/pipeline_subscriptions'
        end

        module Monitor
          module Metrics
            autoload :Show, 'qa/ee/page/project/monitor/metrics/show'
          end
        end

        module Pipeline
          autoload :Show, 'qa/ee/page/project/pipeline/show'
          autoload :Index, 'qa/ee/page/project/pipeline/index'
        end

        module Secure
          autoload :Show, 'qa/ee/page/project/secure/show'
          autoload :DependencyList, 'qa/ee/page/project/secure/dependency_list'
          autoload :SecurityDashboard, 'qa/ee/page/project/secure/security_dashboard'
          autoload :VulnerabilityDetails, 'qa/ee/page/project/secure/vulnerability_details'
          autoload :LicenseCompliance, 'qa/ee/page/project/secure/license_compliance'
          autoload :ConfigurationForm, 'qa/ee/page/project/secure/configuration_form'
        end

        module PathLocks
          autoload :Index, 'qa/ee/page/project/path_locks/index'
        end

        module Packages
          autoload :Index, 'qa/ee/page/project/packages/index'
        end

        module Snippet
          autoload :Index, 'qa/ee/page/project/snippet/index'
        end

        module Job
          autoload :Show, 'qa/ee/page/project/job/show'
        end

        module ThreatMonitoring
          autoload :Index, 'qa/ee/page/project/threat_monitoring/index'
          autoload :AlertsList, 'qa/ee/page/project/threat_monitoring/alerts_list'
        end
      end

      module MergeRequest
        autoload :New, 'qa/ee/page/merge_request/new'
        autoload :Show, 'qa/ee/page/merge_request/show'
      end

      module Group
        autoload :IssuesAnalytics, 'qa/ee/page/group/issues_analytics'
        autoload :Roadmap, 'qa/ee/page/group/roadmap'

        module Epic
          autoload :Index, 'qa/ee/page/group/epic/index'
          autoload :New, 'qa/ee/page/group/epic/new'
          autoload :Show, 'qa/ee/page/group/epic/show'
        end

        module Secure
          autoload :Show, 'qa/ee/page/group/secure/show'
        end
      end

      module Insights
        autoload :Show, 'qa/ee/page/insights/show'
      end
    end

    module Resource
      autoload :License, 'qa/ee/resource/license'
      autoload :Epic, 'qa/ee/resource/epic'
      autoload :GroupIteration, 'qa/ee/resource/group_iteration'
      autoload :ImportRepoWithCiCd, 'qa/ee/resource/import_repo_with_ci_cd'
      autoload :PipelineSubscriptions, 'qa/ee/resource/pipeline_subscriptions'

      module Board
        autoload :BaseBoard, 'qa/ee/resource/board/base_board'
        autoload :GroupBoard, 'qa/ee/resource/board/group_board'
        autoload :ProjectBoard, 'qa/ee/resource/board/project_board'

        module BoardList
          module Group
            autoload :BoardList, 'qa/ee/resource/board/board_list/group/board_list'
          end

          module Project
            autoload :BaseBoardList, 'qa/ee/resource/board/board_list/project/base_board_list'
            autoload :AssigneeBoardList, 'qa/ee/resource/board/board_list/project/assignee_board_list'
            autoload :LabelBoardList, 'qa/ee/resource/board/board_list/project/label_board_list'
            autoload :MilestoneBoardList, 'qa/ee/resource/board/board_list/project/milestone_board_list'
          end
        end
      end

      module Geo
        autoload :Node, 'qa/ee/resource/geo/node'
      end

      module Settings
        autoload :Elasticsearch, 'qa/ee/resource/settings/elasticsearch'
      end
    end

    module Scenario
      module Test
        autoload :Geo, 'qa/ee/scenario/test/geo'
        module Integration
          autoload :GroupSAML, 'qa/ee/scenario/test/integration/group_saml'
          autoload :Elasticsearch, 'qa/ee/scenario/test/integration/elasticsearch'
        end

        module Sanity
          autoload :Selectors, 'qa/ee/scenario/test/sanity/selectors'
        end
      end
    end
  end
end
