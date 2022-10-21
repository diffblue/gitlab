import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import RunnerDetails from '~/ci/runner/components/runner_details.vue';
import RunnerDetail from '~/ci/runner/components/runner_detail.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { UPGRADE_STATUS_AVAILABLE } from 'ee/ci/runner/constants';

import RunnerUpgradeStatusAlert from 'ee_component/ci/runner/components/runner_upgrade_status_alert.vue';
import RunnerMaintenanceNoteDetail from 'ee_component/ci/runner/components/runner_maintenance_note_detail.vue';
import RunnerUpgradeStatusBadge from 'ee_component/ci/runner/components/runner_upgrade_status_badge.vue';

import { runnerData } from 'jest/ci/runner/mock_data';

const mockRunner = runnerData.data.runner;

describe('RunnerDetails', () => {
  let wrapper;

  const findRunnerUpgradeStatusAlert = () => wrapper.findComponent(RunnerUpgradeStatusAlert);
  const findRunnerMaintenanceNoteDetail = () => wrapper.findComponent(RunnerMaintenanceNoteDetail);
  const findRunnerUpgradeStatusBadge = () => wrapper.findComponent(RunnerUpgradeStatusBadge);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RunnerDetails, {
      propsData: {
        ...props,
      },
      ...options,
    });
  };

  describe('Upgrade status', () => {
    describe.each`
      feature                                      | provide
      ${'runner_upgrade_management'}               | ${{ glFeatures: { runnerUpgradeManagement: true } }}
      ${'runner_upgrade_management_for_namespace'} | ${{ glFeatures: { runnerUpgradeManagementForNamespace: true } }}
    `('When $feature is available', ({ provide }) => {
      beforeEach(() => {
        createComponent({
          props: {
            runner: {
              ...mockRunner,
              upgradeStatus: UPGRADE_STATUS_AVAILABLE,
            },
          },
          stubs: {
            GlAlert,
            RunnerDetail,
          },
          provide,
        });
      });

      it('displays upgrade available alert', () => {
        expect(findRunnerUpgradeStatusAlert().text()).toContain(s__('Runners|Upgrade available'));
      });

      it('displays upgrade available badge', () => {
        expect(findRunnerUpgradeStatusBadge().text()).toBe(s__('Runners|Upgrade available'));
      });
    });
  });

  describe('Maintenance Note', () => {
    const mockNoteHtml = 'Note.';

    beforeEach(() => {
      createComponent({
        props: {
          runner: {
            ...mockRunner,
            maintenanceNoteHtml: mockNoteHtml,
          },
        },
        stubs: {
          RunnerDetail,
        },
        provide: {
          glFeatures: {
            runnerMaintenanceNote: true,
          },
        },
      });
    });

    it('displays note', () => {
      expect(findRunnerMaintenanceNoteDetail().text()).toContain(mockNoteHtml);
    });
  });
});
