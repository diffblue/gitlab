import { GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import ToggleLabels from 'ee/boards/components/toggle_labels.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

Vue.use(Vuex);

describe('ToggleLabels component', () => {
  let wrapper;
  let setShowLabels;

  function createComponent(state = {}) {
    setShowLabels = jest.fn();
    return shallowMount(ToggleLabels, {
      store: new Vuex.Store({
        state: {
          isShowingLabels: true,
          ...state,
        },
        actions: {
          setShowLabels,
        },
      }),
      stubs: {
        LocalStorageSync,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('onStorageUpdate parses empty value as false', async () => {
    wrapper = createComponent();

    const localStorageSync = wrapper.findComponent(LocalStorageSync);
    localStorageSync.vm.$emit('input', '');

    await nextTick();

    expect(setShowLabels).toHaveBeenCalledWith(expect.any(Object), false);
  });

  it('sets GlToggle value from store.isShowingLabels', () => {
    wrapper = createComponent({ isShowingLabels: true });

    expect(wrapper.findComponent(GlToggle).props('value')).toEqual(true);

    wrapper = createComponent({ isShowingLabels: false });

    expect(wrapper.findComponent(GlToggle).props('value')).toEqual(false);
  });
});
