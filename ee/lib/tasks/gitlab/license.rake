# frozen_string_literal: true

module Tasks
  class GitlabLicenseTasks
    include Rake::DSL

    def initialize
      namespace :gitlab do
        namespace :license do
          desc 'GitLab | License | Gather license related information'
          task info: :gitlab_environment do
            info
          end

          task :load, [:mode] => :environment do |_, args|
            args.with_defaults(mode: 'default')

            activation_code = ENV['GITLAB_ACTIVATION_CODE']

            if activation_code.present?
              activate(activation_code)
            else
              seed_license(args)
            end
          end
        end
      end
    end

    private

    def info
      license = ::Gitlab::UsageData.license_usage_data
      abort("No license has been applied.") unless license[:license_plan]
      puts "Today's Date: #{Date.today}"
      puts "Current User Count: #{license[:active_user_count]}"
      puts "Max Historical Count: #{license[:historical_max_users]}"
      puts "Max Users in License: #{license[:license_user_count]}"
      puts "License valid from: #{license[:license_starts_at]} to #{license[:license_expires_at]}"
      puts "Email associated with license: #{license[:licensee]['Email']}"
    end

    # TODO: Alter explanation text in verbose mode, after
    # https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/5904 is enabled in production
    def activate(activation_code)
      result = ::GitlabSubscriptions::ActivateService.new.execute(activation_code, automated: true)
      if result[:success]
        puts 'Activation successful'.color(:green)
      else
        puts 'Activation unsuccessful'.color(:red)
        puts Array(result[:errors]).join(' ').color(:red)
        raise 'Activation unsuccessful'
      end
    end

    def seed_license(args)
      flag = 'GITLAB_LICENSE_FILE'
      default_license_file = Settings.source.dirname + 'Gitlab.gitlab-license'
      license_file = ENV.fetch(flag, default_license_file)

      if File.file?(license_file)
        begin
          ::License.create!(data: File.read(license_file))
          puts "License Added:\n\nFilePath: #{license_file}".color(:green)
        rescue ::Gitlab::License::Error, ActiveRecord::RecordInvalid
          puts "License Invalid:\n\nFilePath: #{license_file}".color(:red)
          raise "License Invalid"
        end
      elsif ENV[flag].present?
        puts "License File Missing:\n\nFilePath: #{license_file}".color(:red)
        raise "License File Missing"
      elsif args[:mode] == 'verbose'
        puts "Skipped. Use the `#{flag}` environment variable to seed the License file of the given path."
      end
    end
  end
end

Tasks::GitlabLicenseTasks.new
