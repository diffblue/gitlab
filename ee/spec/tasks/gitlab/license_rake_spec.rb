# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:license namespace rake tasks', :silence_stdout do
  let(:default_license_path) { Settings.source.dirname + 'Gitlab.gitlab-license' }

  before do
    Rake.application.rake_require 'tasks/gitlab/license'
  end

  describe 'info' do
    subject { run_rake_task 'gitlab:license:info' }

    it 'displays information' do
      allow(Gitlab::UsageData).to receive(:license_usage_data).and_return(
        {
          license_plan: 'Foo',
          recorded_at: 1.day.ago,
          uuid: Gitlab::CurrentSettings.uuid,
          hostname: 'example.com',
          version: Gitlab::VERSION,
          installation_type: 'gitlab-development-kit',
          active_user_count: 42,
          edition: 'EE',
          licensee: { 'Email' => 'foo@example.com' }
        }
      )

      expect { subject }.to output(
        include(
          'Current User Count: 42',
          'Email associated with license: foo@example.com'
        )
      ).to_stdout
    end

    context 'when license not found' do
      it 'aborts' do
        allow(Gitlab::UsageData).to receive(:license_usage_data).and_return(
          {
            recorded_at: 1.day.ago,
            uuid: Gitlab::CurrentSettings.uuid,
            hostname: 'example.com',
            version: Gitlab::VERSION,
            installation_type: 'gitlab-development-kit',
            active_user_count: 42,
            edition: 'CE'
          }
        )

        expect { subject }.to raise_error(SystemExit, 'No license has been applied.')
      end
    end
  end

  describe 'load' do
    let_it_be(:license_path) { 'arbitrary_file_name' }

    let(:mode) { 'default' }

    subject { run_rake_task 'gitlab:license:load', [mode] }

    it 'works when no license to be installed' do
      expect { subject }.not_to raise_error
    end

    context 'when GITLAB_ACTIVATION_CODE env variable is set' do
      let(:activation_code) { 'activation_code' }
      let(:license) { build(:license) }
      let(:service_result) { { success: true, license: license } }

      before do
        stub_env('GITLAB_ACTIVATION_CODE', activation_code)
      end

      def expect_activation
        expect_next_instance_of(::GitlabSubscriptions::ActivateService) do |service|
          expect(service)
            .to receive(:execute)
            .with(activation_code, automated: true)
            .and_return(service_result)
        end
      end

      it 'triggers ActivateService in automated mode' do
        expect_activation

        subject
      end

      context 'when ActivateService is unsuccessful' do
        let(:service_result) { { success: false, errors: %w[foo bar] } }

        it 'raises error' do
          expect_activation

          expect { subject }.to raise_error(RuntimeError, 'Activation unsuccessful')
            .and output(/foo bar/).to_stdout
        end
      end

      context 'when errors is not array' do
        let(:service_result) { { success: false, errors: 'CONNECTIVITY_ERROR' } }

        it 'prints error message' do
          expect_activation

          expect { subject }.to raise_error(RuntimeError, 'Activation unsuccessful')
            .and output(/CONNECTIVITY_ERROR/).to_stdout
        end
      end

      context 'when GITLAB_LICENSE_FILE is also set' do
        before do
          stub_env('GITLAB_LICENSE_FILE', license_path)
        end

        it 'activates and ignores license file' do
          expect_activation

          subject
        end
      end
    end

    context 'when GITLAB_LICENSE_FILE env variable is set' do
      before do
        stub_env('GITLAB_LICENSE_FILE', license_path)
      end

      it 'fails when the file does not exist' do
        expect(File).to receive(:file?).with(license_path).and_return(false)
        expect { subject }.to raise_error(RuntimeError, "License File Missing")
      end

      context 'when the file does exist' do
        before do
          expect(File).to receive(:file?).with(license_path).and_return(true)
        end

        context 'and contains a valid license' do
          let(:license) { build(:gitlab_license) }
          let(:license_file_contents) { license.export }

          it 'succeeds in adding the license' do
            expect_file_read(license_path, content: license_file_contents)

            expect { subject }.not_to raise_error
          end
        end

        context 'but does not contain a valid license' do
          let(:license_file_contents) { 'invalid contents' }

          it 'fails to add the license' do
            expect_file_read(license_path, content: license_file_contents)

            expect { subject }.to raise_error(RuntimeError, "License Invalid")
          end
        end

        context 'but contains an expired license' do
          let(:license) { build(:gitlab_license, expires_at: Date.current - 1.month) }
          let(:license_file_contents) { license.export }

          it 'fails to add the license' do
            expect_file_read(license_path, content: license_file_contents)

            expect { subject }.to raise_error(RuntimeError, "License Invalid")
          end
        end
      end
    end

    context 'when GITLAB_LICENSE_FILE env variable is not set' do
      let(:license) { build(:gitlab_license) }
      let(:license_file_contents) { license.export }

      context 'when default valid license file does exist' do
        before do
          allow(File).to receive(:file?).with(default_license_path).and_return(true)
        end

        it 'succeeds in adding the license' do
          expect_file_read(default_license_path, content: license_file_contents)

          expect { subject }.not_to raise_error
        end
      end
    end

    context 'running in mode verbose' do
      let(:mode) { 'verbose' }

      context 'when default valid license file does not exist' do
        it 'outputs a the help message' do
          allow(File).to receive(:file?).with(default_license_path).and_return(false)

          expect { subject }.to output(/environment variable to seed the License file of the given path/).to_stdout
        end
      end
    end
  end
end
