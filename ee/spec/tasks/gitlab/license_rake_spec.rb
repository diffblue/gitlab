# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:license namespace rake tasks', :silence_stdout do
  let(:default_license_path) { Settings.source.dirname + 'Gitlab.gitlab-license' }

  before do
    Rake.application.rake_require 'tasks/gitlab/license'
  end

  describe 'load' do
    let_it_be(:license_path) { 'arbitrary_file_name' }

    let(:mode) { 'default' }

    subject { run_rake_task 'gitlab:license:load', [mode] }

    it 'works when no license to be installed' do
      expect { subject }.not_to raise_error
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
