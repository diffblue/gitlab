import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import deleteExternalDestination from 'ee/audit_events/graphql/delete_external_destination.mutation.graphql';
import { AUDIT_STREAMS_NETWORK_ERRORS, STREAM_ITEMS_I18N } from 'ee/audit_events/constants';
import StreamItem from 'ee/audit_events/components/stream/stream_item.vue';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import {
  destinationDeleteMutationPopulator,
  mockExternalDestinations,
  mockFiltersOptions,
} from '../../mock_data';

jest.mock('~/flash');
Vue.use(VueApollo);

describe('StreamItem', () => {
  let wrapper;

  const destinationWithoutFilters = mockExternalDestinations[0];
  const destinationWithFilters = mockExternalDestinations[1];
  const defaultDeleteSpy = jest.fn().mockResolvedValue(destinationDeleteMutationPopulator());

  const createComponent = (props = {}, deleteExternalDestinationSpy = defaultDeleteSpy) => {
    const mockApollo = createMockApollo([
      [deleteExternalDestination, deleteExternalDestinationSpy],
    ]);
    wrapper = shallowMountExtended(StreamItem, {
      apolloProvider: mockApollo,
      propsData: {
        item: destinationWithoutFilters,
        groupEventFilters: mockFiltersOptions,
        ...props,
      },
      stubs: {
        GlButton,
        GlSprintf,
      },
    });
  };

  const findEditButton = () => wrapper.findByTestId('edit-btn');
  const findDeleteButton = () => wrapper.findByTestId('delete-btn');
  const findEditor = () => wrapper.findComponent(StreamDestinationEditor);
  const findFilterBadge = () => wrapper.findByTestId('filter-badge');

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

    it('should show the edit button', () => {
      expect(findEditButton().exists()).toBe(true);
    });
  });

  describe('deleting', () => {
    it('should emit deleted with item id', async () => {
      createComponent();
      const deleteBtn = findDeleteButton();
      const editBtn = findEditButton();
      await deleteBtn.trigger('click');

      expect(editBtn.props('disabled')).toBe(true);
      expect(deleteBtn.props('loading')).toBe(true);

      await waitForPromises();

      expect(wrapper.emitted('deleted')).toBeDefined();
      expect(editBtn.props('disabled')).toBe(false);
      expect(deleteBtn.props('loading')).toBe(false);
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('should not emit deleted when backend error occurs', async () => {
      const errorMsg = 'Random Error message';
      const deleteExternalDestinationErrorSpy = jest
        .fn()
        .mockResolvedValue(destinationDeleteMutationPopulator([errorMsg]));
      createComponent({}, deleteExternalDestinationErrorSpy);
      const deleteBtn = findDeleteButton();
      const editBtn = findEditButton();

      await deleteBtn.trigger('click');

      expect(editBtn.props('disabled')).toBe(true);
      expect(deleteBtn.props('loading')).toBe(true);

      await waitForPromises();

      expect(wrapper.emitted('deleted')).toBeUndefined();
      expect(editBtn.props('disabled')).toBe(false);
      expect(deleteBtn.props('loading')).toBe(false);
      expect(wrapper.emitted('error')).toBeDefined();
      expect(createAlert).toHaveBeenCalledWith({
        message: errorMsg,
      });
    });

    it('should not emit deleted when network error occurs', async () => {
      const error = new Error('Network error');
      createComponent({}, jest.fn().mockRejectedValue(error));

      const deleteBtn = findDeleteButton();
      const editBtn = findEditButton();

      await deleteBtn.trigger('click');

      expect(editBtn.props('disabled')).toBe(true);
      expect(deleteBtn.props('loading')).toBe(true);

      await waitForPromises();

      expect(wrapper.emitted('deleted')).toBeUndefined();
      expect(editBtn.props('disabled')).toBe(false);
      expect(deleteBtn.props('loading')).toBe(false);
      expect(wrapper.emitted('error')).toBeDefined();
      expect(createAlert).toHaveBeenCalledWith({
        message: AUDIT_STREAMS_NETWORK_ERRORS.DELETING_ERROR,
        captureError: true,
        error,
      });
    });
  });

  describe('editing', () => {
    beforeEach(() => {
      createComponent();
      findEditButton().trigger('click');
    });

    it('should render correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('should pass the item to the editor', () => {
      expect(findEditor().exists()).toBe(true);
      expect(findEditor().props('item')).toStrictEqual(mockExternalDestinations[0]);
    });

    it('should emit the updated event when the editor fires its update event', async () => {
      findEditor().vm.$emit('updated');
      await waitForPromises();

      expect(wrapper.emitted('updated')).toBeDefined();
      expect(findEditor().exists()).toBe(false);
    });

    it('should emit the error event when the editor fires its error event', () => {
      findEditor().vm.$emit('error');

      expect(wrapper.emitted('error')).toBeDefined();
      expect(findEditor().exists()).toBe(true);
    });

    it('should close the editor when the editor fires its cancel event', async () => {
      findEditor().vm.$emit('cancel');
      await waitForPromises();

      expect(findEditor().exists()).toBe(false);
    });
  });

  describe('when an item has event filters', () => {
    beforeEach(() => {
      createComponent({ item: destinationWithFilters });
    });

    it('should show filter badge', () => {
      expect(findFilterBadge().text()).toBe(STREAM_ITEMS_I18N.FILTER_BADGE_LABEL);
      expect(findFilterBadge().attributes('id')).toBe(destinationWithFilters.id);
    });

    it('renders a popover', () => {
      expect(wrapper.findByTestId('filter-popover').element).toMatchSnapshot();
    });
  });

  describe('when an item has no filter', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not show filter badge', () => {
      expect(findFilterBadge().exists()).toBe(false);
    });
  });
});
