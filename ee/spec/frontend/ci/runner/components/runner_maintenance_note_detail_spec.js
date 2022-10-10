import { s__ } from '~/locale';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerDetail from '~/ci/runner/components/runner_detail.vue';

import RunnerMaintenanceNoteDetail from 'ee_component/ci/runner/components/runner_maintenance_note_detail.vue';

describe('RunnerMaintenanceNoteDetail', () => {
  let wrapper;

  const findRunnerDetail = () => wrapper.findComponent(RunnerDetail);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RunnerMaintenanceNoteDetail, {
      propsData: {
        ...props,
      },
      ...options,
    });
  };

  describe('when runner_maintenance_note is enabled, note is present', () => {
    const provide = {
      glFeatures: { runnerMaintenanceNote: true },
    };

    it('note is present', () => {
      createComponent({
        provide,
      });

      expect(findRunnerDetail().exists()).toBe(true);
    });

    it('note is shown', () => {
      const value = 'Note.';

      createComponent({
        props: {
          value,
        },
        provide,
      });

      expect(findRunnerDetail().props('label')).toBe(s__('Runners|Maintenance note'));
      expect(findRunnerDetail().text()).toBe(value);
    });

    it('note shows empty state', () => {
      const value = null;

      createComponent({
        props: {
          value,
        },
        mountFn: mountExtended,
        provide,
      });

      expect(findRunnerDetail().props('label')).toBe(s__('Runners|Maintenance note'));
      expect(findRunnerDetail().find('dd').text()).toBe('None');
    });
  });

  describe('when runner_maintenance_note is disabled', () => {
    const provide = {
      glFeatures: { runnerMaintenanceNote: false },
    };

    it('note is not present', () => {
      createComponent({
        provide,
      });

      expect(findRunnerDetail().exists()).toBe(false);
    });
  });
});
