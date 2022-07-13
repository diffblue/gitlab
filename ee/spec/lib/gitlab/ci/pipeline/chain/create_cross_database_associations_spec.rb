# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::CreateCrossDatabaseAssociations do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:outsider) { create(:user) }

  let!(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let!(:stage) { create(:ci_stage, project: project, pipeline: pipeline, name: :dast) }

  subject do
    command = Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user)

    described_class.new(pipeline, command)
  end

  describe '#perform!' do
    shared_examples 'it failed' do
      it 'breaks the chain' do
        expect(subject.break?).to be(true)
      end

      it 'attaches errors to the pipeline' do
        expect(pipeline.errors.full_messages).to contain_exactly(*errors)
      end
    end

    context 'dast' do
      let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
      let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

      let(:dast_site_profile_name) { dast_site_profile.name }
      let(:dast_scanner_profile_name) { dast_scanner_profile.name }

      let!(:dast_build) { create(:ci_build, project: project, user: user, pipeline: pipeline, stage_id: stage.id, options: { dast_configuration: { site_profile: dast_site_profile_name, scanner_profile: dast_scanner_profile_name } }) }

      context 'when the feature is not licensed' do
        before do
          subject.perform!
        end

        it_behaves_like 'it failed' do
          let(:errors) { ['Insufficient permissions for dast_configuration keyword'] }
        end
      end

      context 'when the feature is licensed' do
        before do
          stub_licensed_features(security_on_demand_scans: true)
          subject.perform!
        end

        shared_examples 'it attempts to associate the profile' do |dast_profile_name_key|
          let(:association) { dast_build.public_send(profile.class.underscore.to_sym) }
          let(:profile_name) { public_send(dast_profile_name_key) }

          context 'when the profile exists' do
            it 'assigns the association' do
              expect(association).to eq(profile)
            end
          end

          shared_examples 'it has no effect' do
            it 'does not assign the association' do
              expect(association).to be_nil
            end
          end

          context 'when the profile is not provided' do
            let(dast_profile_name_key) { nil }

            it_behaves_like 'it has no effect'
          end

          context 'when the stage is not dast' do
            let!(:stage) { create(:ci_stage, project: project, pipeline: pipeline, name: :test) }

            it_behaves_like 'it has no effect'
          end

          context 'when the profile does not exist' do
            let(dast_profile_name_key) { SecureRandom.hex }

            it_behaves_like 'it failed' do
              let(:errors) { "DAST profile not found: #{profile_name}" }
            end
          end
        end

        context 'dast_site_profile' do
          let(:profile) { dast_site_profile }

          it_behaves_like 'it attempts to associate the profile', :dast_site_profile_name
        end

        context 'dast_scanner_profile' do
          let(:profile) { dast_scanner_profile }

          it_behaves_like 'it attempts to associate the profile', :dast_scanner_profile_name
        end

        context 'when the user cannot create dast scans' do
          let_it_be(:user) { outsider }

          it_behaves_like 'it failed' do
            let(:errors) { ['Insufficient permissions for dast_configuration keyword'] }
          end
        end
      end
    end
  end
end
