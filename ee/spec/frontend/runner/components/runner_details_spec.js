import { s__ } from '~/locale';
import RunnerDetails from '~/runner/components/runner_details.vue';
import RunnerDetail from '~/runner/components/runner_detail.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { findDd } from 'helpers/dl_locator_helper';

import { runnerData } from 'jest/runner/mock_data';

const mockRunner = runnerData.data.runner;

describe('RunnerDetails', () => {
  let wrapper;

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RunnerDetails, {
      propsData: {
        ...props,
      },
      stubs: {
        RunnerDetail,
      },
      ...options,
    });
  };

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
        provide: {
          glFeatures: {
            runnerMaintenanceNote: true,
          },
        },
      });
    });

    it('displays note', () => {
      expect(findDd(s__('Runners|Maintenance note'), wrapper).text()).toBe(mockNoteHtml);
    });
  });
});
