import VueApollo from 'vue-apollo';
import { createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import deleteExternalDestination from 'ee/audit_events/graphql/delete_external_destination.mutation.graphql';
import { AUDIT_STREAMS_NETWORK_ERRORS } from 'ee/audit_events/constants';
import StreamItem from 'ee/audit_events/components/stream/stream_item.vue';
import { mockExternalDestinations } from '../../mock_data';

jest.mock('~/flash');
const localVue = createLocalVue();
localVue.use(VueApollo);
describe('StreamItem', () => {
  let wrapper;

  const mutate = jest.fn().mockResolvedValue({
    data: {
      externalAuditEventDestinationDestroy: {
        errors: [],
      },
    },
  });

  const createComponent = (deleteExternalDestinationSpy = mutate) => {
    const mockApollo = createMockApollo([
      [deleteExternalDestination, deleteExternalDestinationSpy],
    ]);
    wrapper = shallowMountExtended(StreamItem, {
      apolloProvider: mockApollo,
      propsData: {
        item: mockExternalDestinations[0],
      },
      stubs: {
        GlButton,
      },
      localVue,
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    wrapper.destroy();
    createAlert.mockClear();
  });

  describe('render', () => {
    it('should render correctly', () => {
      createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('events', () => {
    it('should emit delete with item id', async () => {
      createComponent();
      const button = findButton();
      await button.trigger('click');

      expect(button.props('loading')).toBe(true);

      await waitForPromises();

      expect(wrapper.emitted('delete')).toBeDefined();
      expect(button.props('loading')).toBe(false);
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('should not emit delete when backend error occurs', async () => {
      const errorMsg = 'Random Error message';
      const deleteExternalDestinationErrorSpy = jest.fn().mockResolvedValue({
        data: {
          externalAuditEventDestinationDestroy: {
            errors: [errorMsg],
          },
        },
      });
      createComponent(deleteExternalDestinationErrorSpy);
      const button = findButton();
      await button.trigger('click');

      expect(button.props('loading')).toBe(true);

      await waitForPromises();

      expect(wrapper.emitted('delete')).not.toBeDefined();
      expect(button.props('loading')).toBe(false);
      expect(createAlert).toHaveBeenCalledWith({
        message: errorMsg,
      });
    });

    it('should not emit delete when network error occurs', async () => {
      const error = new Error('Network error');
      const deleteExternalDestinationErrorSpy = jest.fn().mockRejectedValue(error);
      createComponent(deleteExternalDestinationErrorSpy);
      const button = findButton();
      await button.trigger('click');

      expect(button.props('loading')).toBe(true);

      await waitForPromises();

      expect(wrapper.emitted('delete')).not.toBeDefined();
      expect(button.props('loading')).toBe(false);
      expect(createAlert).toHaveBeenCalledWith({
        message: AUDIT_STREAMS_NETWORK_ERRORS.DELETING_ERROR,
        captureError: true,
        error,
      });
    });
  });
});
