import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';

import { __ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/roadmap/store';
import RoadmapEpicsState from 'ee/roadmap/components/roadmap_epics_state.vue';
import { EPICS_STATES } from 'ee/roadmap/constants';

describe('RoadmapEpicsState', () => {
  let wrapper;

  const availableStates = [
    { text: __('Show all epics'), value: EPICS_STATES.ALL },
    { text: __('Show open epics'), value: EPICS_STATES.OPENED },
    { text: __('Show closed epics'), value: EPICS_STATES.CLOSED },
  ];

  const createComponent = () => {
    const store = createStore();

    store.dispatch('setInitialData', {
      epicsState: EPICS_STATES.All,
    });

    wrapper = shallowMountExtended(RoadmapEpicsState, {
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
      expect(findFormGroup().attributes('label')).toBe('Epics');
    });

    it('renders radio form group', () => {
      expect(findFormRadioGroup().exists()).toBe(true);
      expect(findFormRadioGroup().props('options')).toEqual(availableStates);
    });
  });
});
