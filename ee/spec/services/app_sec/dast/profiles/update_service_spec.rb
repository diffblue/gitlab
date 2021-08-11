# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Profiles::UpdateService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_profile, reload: true) { create(:dast_profile, project: project, branch_name: 'orphaned-branch') }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

  let(:default_params) do
    {
      name: SecureRandom.hex,
      description: SecureRandom.hex,
      branch_name: 'orphaned-branch',
      dast_profile: dast_profile,
      dast_site_profile_id: dast_site_profile.id,
      dast_scanner_profile_id: dast_scanner_profile.id
    }
  end

  let(:params) { default_params }

  subject do
    described_class.new(
      container: project,
      current_user: user,
      params: params
    ).execute
  end

  describe 'execute', :clean_gitlab_redis_shared_state do
    context 'when on demand scan licensed feature is not available' do
      it 'communicates failure' do
        stub_licensed_features(security_on_demand_scans: false)

        aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('You are not authorized to update this profile')
        end
      end
    end

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when the user cannot run a DAST scan' do
        it 'communicates failure' do
          aggregate_failures do
            expect(subject.status).to eq(:error)
            expect(subject.message).to eq('You are not authorized to update this profile')
          end
        end
      end

      context 'when the user can run a DAST scan' do
        before do
          project.add_developer(user)
        end

        it 'communicates success' do
          expect(subject.status).to eq(:success)
        end

        it 'updates the dast_profile' do
          updated_dast_profile = subject.payload[:dast_profile].reload

          aggregate_failures do
            expect(updated_dast_profile.dast_site_profile.id).to eq(params[:dast_site_profile_id])
            expect(updated_dast_profile.dast_scanner_profile.id).to eq(params[:dast_scanner_profile_id])
            expect(updated_dast_profile.name).to eq(params[:name])
            expect(updated_dast_profile.description).to eq(params[:description])
          end
        end

        context 'with dast_profile_schedule param' do
          let_it_be(:time_zone) { Time.zone.tzinfo.name }

          let(:params) do
            default_params.merge(
              dast_profile_schedule: {
                active: false,
                starts_at: Time.zone.now + 10.days,
                timezone: time_zone,
                cadence: { unit: 'month', duration: 1 }
              }
            )
          end

          context 'when associated schedule is not present' do
            it 'communicates failure for dast_profile_schedule' do
              aggregate_failures do
                expect(dast_profile.dast_profile_schedule).to be nil
                expect(subject.status).to eq(:error)
                expect(subject.message).to include('Dast Profile Schedule not found')
              end
            end
          end

          context 'when associated schedule is present' do
            before do
              create(:dast_profile_schedule, dast_profile: dast_profile)
            end

            it 'updates the dast profile schedule' do
              updated_schedule = subject.payload[:dast_profile_schedule].reload

              aggregate_failures do
                expect(updated_schedule.active).to eq(params[:dast_profile_schedule][:active])
                expect(updated_schedule.starts_at.to_i).to eq(params[:dast_profile_schedule][:starts_at].to_i)
                expect(updated_schedule.timezone).to eq(params[:dast_profile_schedule][:timezone])
                expect(updated_schedule.cadence).to eq(params[:dast_profile_schedule][:cadence].stringify_keys)
              end
            end

            it 'creates the audit event' do
              expect { subject }.to change { AuditEvent.where(target_id: dast_profile.dast_profile_schedule.id).count }
            end
          end
        end

        it 'audits the update', :aggregate_failures do
          old_profile_attrs = {
            description: dast_profile.description,
            name: dast_profile.name,
            scanner_profile_name: dast_profile.dast_scanner_profile.name,
            site_profile_name: dast_profile.dast_site_profile.name
          }

          subject

          new_profile = dast_profile.reload
          audit_events = AuditEvent.where(author_id: user.id)

          audit_events.each do |event|
            expect(event.author).to eq(user)
            expect(event.entity).to eq(project)
            expect(event.target_id).to eq(new_profile.id)
            expect(event.target_type).to eq('Dast::Profile')
            expect(event.target_details).to eq(new_profile.name)
          end

          messages = audit_events.map(&:details).pluck(:custom_message)
          expected_messages = [
            "Changed DAST profile dast_scanner_profile from #{old_profile_attrs[:scanner_profile_name]} to #{dast_scanner_profile.name}",
            "Changed DAST profile dast_site_profile from #{old_profile_attrs[:site_profile_name]} to #{dast_site_profile.name}",
            "Changed DAST profile name from #{old_profile_attrs[:name]} to #{new_profile.name}",
            "Changed DAST profile description from #{old_profile_attrs[:description]} to #{new_profile.description}"
          ]
          expect(messages).to match_array(expected_messages)
        end

        context 'when param run_after_update: true' do
          let(:params) { default_params.merge(run_after_update: true) }

          it_behaves_like 'it delegates scan creation to another service' do
            let(:delegated_params) { hash_including(dast_profile: dast_profile) }
          end

          it 'creates a ci_pipeline' do
            expect { subject }.to change { Ci::Pipeline.count }.by(1)
          end
        end

        context 'when dast_profile param is missing' do
          let(:params) { {} }

          it 'communicates failure' do
            aggregate_failures do
              expect(subject.status).to eq(:error)
              expect(subject.message).to eq('Profile parameter missing')
            end
          end
        end
      end
    end
  end
end
