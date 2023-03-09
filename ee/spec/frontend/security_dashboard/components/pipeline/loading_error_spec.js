import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LoadingError from 'ee/security_dashboard/components/pipeline/loading_error.vue';
import { HTTP_STATUS_FORBIDDEN, HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';

const illustrations = {
  [HTTP_STATUS_UNAUTHORIZED]: '/401.svg',
  [HTTP_STATUS_FORBIDDEN]: '/403.svg',
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

  describe.each([HTTP_STATUS_UNAUTHORIZED, HTTP_STATUS_FORBIDDEN])(
    'with error code %s',
    (errorCode) => {
      beforeEach(() => {
        createWrapper(errorCode);
      });

      it('renders an empty state', () => {
        expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
      });

      it('empty state has correct props', () => {
        expect(wrapper.findComponent(GlEmptyState).props()).toMatchSnapshot();
      });
    },
  );
});
