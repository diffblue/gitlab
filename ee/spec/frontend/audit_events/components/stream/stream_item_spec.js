import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import deleteExternalDestination from 'ee/audit_events/graphql/delete_external_destination.mutation.graphql';
import { AUDIT_STREAMS_NETWORK_ERRORS } from 'ee/audit_events/constants';
import StreamItem from 'ee/audit_events/components/stream/stream_item.vue';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import { destinationDeleteMutationPopulator, mockExternalDestinations } from '../../mock_data';

jest.mock('~/flash');
Vue.use(VueApollo);

describe('StreamItem', () => {
  let wrapper;

  const createComponent = (
    injectedProps = {},
    deleteExternalDestinationSpy = jest
      .fn()
      .mockResolvedValue(destinationDeleteMutationPopulator()),
  ) => {
    const mockApollo = createMockApollo([
      [deleteExternalDestination, deleteExternalDestinationSpy],
    ]);
    wrapper = shallowMountExtended(StreamItem, {
      apolloProvider: mockApollo,
      provide: {
        showStreamsHeaders: false,
        ...injectedProps,
      },
      propsData: {
        item: mockExternalDestinations[0],
      },
      stubs: {
        GlButton,
      },
    });
  };

  const findEditButton = () => wrapper.findByTestId('edit-btn');
  const findDeleteButton = () => wrapper.findByTestId('delete-btn');
  const findEditor = () => wrapper.findComponent(StreamDestinationEditor);

  afterEach(() => {
    wrapper.destroy();
    createAlert.mockClear();
  });

  describe('render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('should not show the editor', () => {
      expect(findEditor().exists()).toBe(false);
    });

    it('should not show the edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('with the streaming headers', () => {
    beforeEach(() => {
      createComponent({ showStreamsHeaders: true });
    });

    it('should show the edit button', () => {
      expect(findEditButton().exists()).toBe(true);
    });
  });

  describe('events', () => {
    it('should emit delete with item id', async () => {
      createComponent();
      const button = findDeleteButton();
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
      createComponent({}, deleteExternalDestinationErrorSpy);
      const button = findDeleteButton();
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
      createComponent({}, jest.fn().mockRejectedValue(error));
      const button = findDeleteButton();
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

  describe('editing', () => {
    beforeEach(() => {
      createComponent({ showStreamsHeaders: true });
      findEditButton().trigger('click');
    });

    it('should render correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('should pass the item to the editor', () => {
      expect(findEditor().exists()).toBe(true);
      expect(findEditor().props('item')).toStrictEqual(mockExternalDestinations[0]);
    });

    it('should emit the updated event when the editor fires its added event', async () => {
      findEditor().vm.$emit('added');
      await waitForPromises();

      expect(wrapper.emitted('updated')).toBeDefined();
      expect(findEditor().exists()).toBe(false);
    });

    it('should close the editor when the editor fires its cancel event', async () => {
      findEditor().vm.$emit('cancel');
      await waitForPromises();

      expect(findEditor().exists()).toBe(false);
    });
  });
});
