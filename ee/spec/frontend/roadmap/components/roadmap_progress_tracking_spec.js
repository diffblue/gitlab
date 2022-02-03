import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/roadmap/store';
import RoadmapProgressTracking from 'ee/roadmap/components/roadmap_progress_tracking.vue';
import { PROGRESS_WEIGHT, PROGRESS_TRACKING_OPTIONS } from 'ee/roadmap/constants';

describe('RoadmapProgressTracking', () => {
  let wrapper;

  const createComponent = () => {
    const store = createStore();

    store.dispatch('setInitialData', {
      progressTracking: PROGRESS_WEIGHT,
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

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders form group', () => {
      expect(findFormGroup().exists()).toBe(true);
      expect(findFormGroup().attributes('label')).toBe('Progress tracking');
    });

    it('renders radio form group', () => {
      expect(findFormRadioGroup().exists()).toBe(true);
      expect(findFormRadioGroup().props('options')).toEqual(PROGRESS_TRACKING_OPTIONS);
    });
  });
});
