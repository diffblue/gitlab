import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DependencyListIncompleteAlert from 'ee/dependencies/components/dependency_list_incomplete_alert.vue';

describe('DependencyListIncompleteAlert component', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMount(DependencyListIncompleteAlert, {
      ...options,
    });
  };

  it('matches the snapshot', () => {
    factory();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when the GlAlert component emits a dismiss event', () => {
    let dismissListenerSpy;

    beforeEach(() => {
      dismissListenerSpy = jest.fn();

      factory({
        listeners: {
          dismiss: dismissListenerSpy,
        },
      });

      wrapper.findComponent(GlAlert).vm.$emit('dismiss');
    });

    it('calls the given listener', () => {
      expect(dismissListenerSpy).toHaveBeenCalledTimes(1);
    });
  });
});
