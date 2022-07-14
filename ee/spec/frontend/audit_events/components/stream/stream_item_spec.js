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
import { destinationDeleteMutationPopulator, mockExternalDestinations } from '../../mock_data';

jest.mock('~/flash');
const localVue = createLocalVue();
localVue.use(VueApollo);

describe('StreamItem', () => {
  let wrapper;

  const createComponent = (
    deleteExternalDestinationSpy = jest
      .fn()
      .mockResolvedValue(destinationDeleteMutationPopulator()),
  ) => {
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
      const deleteExternalDestinationErrorSpy = jest
        .fn()
        .mockResolvedValue(destinationDeleteMutationPopulator([errorMsg]));
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
      createComponent(jest.fn().mockRejectedValue(error));
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
