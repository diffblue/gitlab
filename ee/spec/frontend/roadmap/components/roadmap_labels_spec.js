import { GlToggle } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/roadmap/store';
import RoadmapLabels from 'ee/roadmap/components/roadmap_toggle_labels.vue';

describe('RoadmapLabels', () => {
  let wrapper;
  let store;

  const createComponent = ({ isShowingLabels = false } = {}) => {
    store = createStore();

    store.dispatch('setInitialData', {
      isShowingLabels,
    });

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMountExtended(RoadmapLabels, {
      store,
    });
  };

  const findToggle = () => wrapper.findComponent(GlToggle);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders toggle', () => {
      expect(findToggle().exists()).toBe(true);
      expect(findToggle().attributes('label')).toBe('Show labels');
    });

    it.each`
      isShowingLabels
      ${true}
      ${false}
    `('displays toggle value depending on isShowingLabels', ({ isShowingLabels }) => {
      createComponent({ isShowingLabels });

      expect(findToggle().props('value')).toBe(isShowingLabels);
    });

    it('calls toggleLabels on click toggle', () => {
      expect(store.dispatch).not.toHaveBeenCalledWith('toggleLabels');
      findToggle().vm.$emit('change', true);
      expect(store.dispatch).toHaveBeenCalledWith('toggleLabels', true);
    });
  });
});
