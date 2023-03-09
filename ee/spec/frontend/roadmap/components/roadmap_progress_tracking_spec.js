import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/roadmap/store';
import RoadmapProgressTracking from 'ee/roadmap/components/roadmap_progress_tracking.vue';
import { PROGRESS_WEIGHT, PROGRESS_TRACKING_OPTIONS } from 'ee/roadmap/constants';

describe('RoadmapProgressTracking', () => {
  let wrapper;

  const createComponent = ({ isProgressTrackingActive = true } = {}) => {
    const store = createStore();

    store.dispatch('setInitialData', {
      progressTracking: PROGRESS_WEIGHT,
      isProgressTrackingActive,
    });

    wrapper = shallowMountExtended(RoadmapProgressTracking, {
      store,
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders form group', () => {
      expect(findFormGroup().exists()).toBe(true);
      expect(findFormGroup().attributes('label')).toBe('Progress tracking');
    });

    it.each`
      isProgressTrackingActive
      ${true}
      ${false}
    `(
      'displays radio form group depending on isProgressTrackingActive',
      ({ isProgressTrackingActive }) => {
        createComponent({ isProgressTrackingActive });

        expect(findFormRadioGroup().exists()).toBe(isProgressTrackingActive);
        if (isProgressTrackingActive) {
          expect(findFormRadioGroup().props('options')).toEqual(PROGRESS_TRACKING_OPTIONS);
        }
      },
    );
  });
});
