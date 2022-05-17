# frozen_string_literal: true

require 'net/http'
require 'json'

module QA
  module EE
    module Scenario
      module Test
        class Geo < QA::Scenario::Template
          include QA::Scenario::Bootable
          include QA::Scenario::SharedAttributes

          tags :geo

          attribute :geo_primary_address, '--primary-address PRIMARY'
          attribute :geo_primary_name, '--primary-name PRIMARY_NAME'
          attribute :geo_secondary_address, '--secondary-address SECONDARY'
          attribute :geo_secondary_name, '--secondary-name SECONDARY_NAME'
          attribute :geo_skip_setup?, '--without-setup'

          def perform(options, *rspec_options)
            # Alias QA::Runtime::Scenario.gitlab_address to @address since
            # some components depends on QA::Runtime::Scenario.gitlab_address.
            QA::Support::GitlabAddress.define_gitlab_address_attribute!(QA::Runtime::Scenario.geo_primary_address)
            QA::Runtime::Scenario.define(:network, 'geo')

            unless options[:geo_skip_setup?]
              Geo::Primary.act do
                add_license
                set_replication_password
                set_primary_node
                add_secondary_node
              end

              Geo::Secondary.act do
                replicate_database
                reconfigure
                wait_for_services
                authorize
              end
            end

            # Save the scenario class name
            QA::Runtime::Scenario.define(:klass, self.class.name)

            Specs::Runner.perform do |specs|
              specs.tty = true
              specs.tags = self.class.focus
              specs.options = rspec_options if rspec_options.any?
            end
          end

          class Primary
            include QA::Scenario::Actable

            def initialize
              @name = QA::Runtime::Scenario.geo_primary_name
              @address = QA::Runtime::Scenario.geo_primary_address
            end

            def add_license
              puts 'Adding GitLab EE license ...'

              QA::Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
                Resource::License.fabricate!(ENV['EE_LICENSE'])
              end
            end

            def add_secondary_node
              puts 'Adding new Geo secondary node ...'

              QA::Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
                Resource::Geo::Node.fabricate! do |node|
                  node.name = QA::Runtime::Scenario.geo_secondary_name
                  node.address = QA::Runtime::Scenario.geo_secondary_address
                end
              end
            end

            def set_replication_password
              puts 'Setting replication password on primary node ...'

              QA::Service::Omnibus.new(@name).act do
                gitlab_ctl 'set-replication-password', input: 'echo mypass'
              end
            end

            def set_primary_node
              puts 'Making this node a primary node  ...'

              QA::Service::Omnibus.new(@name).act do
                gitlab_ctl 'set-geo-primary-node'
              end
            end
          end

          class Secondary
            include QA::Scenario::Actable

            WAIT_FOR_SERVICES_SECS = 120

            def initialize
              @address = QA::Runtime::Scenario.geo_secondary_address
              @name = QA::Runtime::Scenario.geo_secondary_name
            end

            def replicate_database
              puts 'Starting Geo replication on secondary node ...'

              QA::Service::Omnibus.new(@name).act do
                require 'uri'

                # At this stage of the workflow, the 'geo-logcursor' service will
                # be 'flapping' because the Secondary DB has not been replicated
                # and is known to timeout when a `gitlab-ctl stop` is issued
                # (it is called as part of the `replicate-geo-database`
                # command).
                #
                # The timeout occurs because it can take longer than 60 secs for
                # 'geo-logcursor' to stop, which is the maximum length of time
                # runit will wait before deeming the service to 'timeout' and
                # then returns a non-zero exit code.
                #
                # Let's always ensure we return a zero exit code here.
                gitlab_ctl "stop || true"

                host = URI(QA::Runtime::Scenario.geo_primary_address).host
                slot = QA::Runtime::Scenario.geo_primary_name.tr('-', '_')

                gitlab_ctl "replicate-geo-database --host=#{host} --slot-name=#{slot} " \
                           "--sslmode=disable --no-wait --force", input: 'echo mypass'
              end
            end

            def reconfigure
              # Without this step, the /var/opt/gitlab/postgresql/data/pg_hba.conf
              # that is left behind from 'gitlab_ctl "replicate-geo-database ..'
              # does not allow PostgreSQL to work.
              puts 'Reconfiguring ...'

              QA::Service::Omnibus.new(@name).act do
                gitlab_ctl 'reconfigure'
              end
            end

            def wait_for_services
              puts 'Waiting until secondary node services are ready ...'

              elapsed = try_for(WAIT_FOR_SERVICES_SECS) do |elapsed|
                break elapsed if host_ready?
              end

              puts "\nSecondary ready after #{elapsed} seconds."
            rescue TryForExceeded
              raise "Secondary node did not start correctly after #{WAIT_FOR_SERVICES_SECS} seconds!"
            end

            def authorize
              # Provide OAuth authorization now so that tests don't have to
              QA::Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
                QA::Page::Main::Login.perform(&:sign_in_using_credentials)
                QA::Page::Main::OAuth.perform do |oauth|
                  oauth.authorize! if oauth.needs_authorization?
                end
              end
            end

            private

            TryForExceeded = Class.new(StandardError)

            def try_for(secs)
              start = Time.new

              loop do
                elapsed = (Time.new - start).round(2)
                break elapsed if elapsed >= secs

                yield elapsed
                sleep 1
              end

              raise TryForExceeded
            end

            def host_ready?
              return true if host_status_ok?

              print '.'
              false
            rescue StandardError
              print 'e'
              false
            end

            def host_status_ok?
              body = Net::HTTP.get(URI.join(@address, '/-/readiness'))
              JSON.parse(body)['status'] == 'ok'
            end
          end
        end
      end
    end
  end
end
