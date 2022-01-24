import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LoadingError from 'ee/security_dashboard/components/pipeline/loading_error.vue';

const illustrations = {
  401: '/401.svg',
  403: '/403.svg',
};

describe('LoadingError component', () => {
  let wrapper;

  const createWrapper = (errorCode) => {
    wrapper = shallowMount(LoadingError, {
      propsData: {
        errorCode,
        illustrations,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each([401, 403])('with error code %s', (errorCode) => {
    beforeEach(() => {
      createWrapper(errorCode);
    });

    it('renders an empty state', () => {
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('empty state has correct props', () => {
      expect(wrapper.findComponent(GlEmptyState).props()).toMatchSnapshot();
    });
  });
});
