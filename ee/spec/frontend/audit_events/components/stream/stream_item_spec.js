import { GlDisclosureDropdown, GlFormInputGroup } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { AUDIT_STREAMS_NETWORK_ERRORS, STREAM_ITEMS_I18N } from 'ee/audit_events/constants';
import StreamItem from 'ee/audit_events/components/stream/stream_item.vue';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import StreamDeleteModal from 'ee/audit_events/components/stream/stream_delete_modal.vue';
import {
  groupPath,
  mockExternalDestinations,
  instanceGroupPath,
  mockInstanceExternalDestinations,
} from '../../mock_data';

jest.mock('~/alert');

describe('StreamItem', () => {
  let wrapper;

  const destinationWithoutFilters = mockExternalDestinations[0];
  const destinationWithFilters = mockExternalDestinations[1];
  const instanceDestination = mockInstanceExternalDestinations[0];
  const showModalSpy = jest.fn();

  let groupPathProvide = groupPath;
  let itemProvide = destinationWithoutFilters;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(StreamItem, {
      attachTo: document.body,
      propsData: {
        item: itemProvide,
        ...props,
      },
      provide: {
        groupPath: groupPathProvide,
      },
      stubs: {
        StreamDestinationEditor: true,
        GlModal: {
          template: '<div class="modal-stub"><slot></slot></div>',
          methods: {
            show: showModalSpy,
          },
        },
      },
    });
  };

  const findToggleButton = () => wrapper.findByTestId('toggle-btn');
  const findEditButton = () => wrapper.findByTestId('edit-btn');
  const findDeleteButton = () => wrapper.findByTestId('delete-btn');
  const findDeleteModal = () => wrapper.findComponent(StreamDeleteModal);
  const findViewButton = () => wrapper.findByTestId('view-btn');
  const findActionsDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findEditor = () => wrapper.findComponent(StreamDestinationEditor);
  const findFilterBadge = () => wrapper.findByTestId('filter-badge');

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('Group StreamItem', () => {
    describe('render', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should not render the editor', () => {
        expect(findEditor().exists()).toBe(false);
      });

      it('renders the delete modal', () => {
        expect(findDeleteModal().exists()).toBe(true);
      });
    });

    describe('deleting', () => {
      beforeEach(() => {
        createComponent({});
        findDeleteModal().vm.$emit('deleting');
      });

      it('should emit deleted on success operation', async () => {
        const deleteBtn = findDeleteButton();
        await deleteBtn.trigger('click');

        await waitForPromises();

        expect(findDeleteModal().props('item')).toBe(itemProvide);
      });

      it('should set loading when emit deleting', () => {
        findDeleteModal().vm.$emit('deleting');
        expect(findActionsDropdown().props('loading')).toBe(true);
      });

      it('shows the alert for the error', () => {
        const errorMsg = 'An error occurred';
        findDeleteModal().vm.$emit('error', errorMsg);

        expect(createAlert).toHaveBeenCalledWith({
          message: AUDIT_STREAMS_NETWORK_ERRORS.DELETING_ERROR,
          captureError: true,
          error: errorMsg,
        });
      });
    });

    describe('editing', () => {
      beforeEach(async () => {
        createComponent();
        await findToggleButton().vm.$emit('click');
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

    it('renders editor when clicking Edit button', async () => {
      createComponent();

      await findEditButton().trigger('click');

      expect(findEditor().exists()).toBe(true);
    });

    it('should show modal when viewing token', async () => {
      createComponent();

      await findViewButton().trigger('click');

      expect(showModalSpy).toHaveBeenCalled();
      expect(
        wrapper.findComponent('.modal-stub').findComponent(GlFormInputGroup).props('value'),
      ).toBe(destinationWithoutFilters.verificationToken);
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

  describe('Instance StreamItem', () => {
    beforeEach(() => {
      groupPathProvide = instanceGroupPath;
      itemProvide = instanceDestination;
    });

    describe('render', () => {
      beforeEach(() => {
        createComponent({});
      });

      it('should not render the editor', () => {
        expect(findEditor().exists()).toBe(false);
      });

      it('renders the delete modal', () => {
        expect(findDeleteModal().exists()).toBe(true);
      });
    });

    describe('deleting', () => {
      beforeEach(() => {
        createComponent({});
        findDeleteModal().vm.$emit('deleting');
      });

      it('should emit deleted on success operation', async () => {
        const deleteBtn = findDeleteButton();
        await deleteBtn.trigger('click');

        await waitForPromises();

        expect(findDeleteModal().props('item')).toBe(itemProvide);
      });

      it('should set loading when emit deleting', () => {
        findDeleteModal().vm.$emit('deleting');
        expect(findActionsDropdown().props('loading')).toBe(true);
      });

      it('shows the alert for the error', () => {
        const errorMsg = 'An error occurred';
        findDeleteModal().vm.$emit('error', errorMsg);

        expect(createAlert).toHaveBeenCalledWith({
          message: AUDIT_STREAMS_NETWORK_ERRORS.DELETING_ERROR,
          captureError: true,
          error: errorMsg,
        });
      });
    });

    describe('editing', () => {
      beforeEach(async () => {
        createComponent({});
        await findToggleButton().vm.$emit('click');
      });

      it('should pass the item to the editor', () => {
        expect(findEditor().exists()).toBe(true);
        expect(findEditor().props('item')).toStrictEqual(mockInstanceExternalDestinations[0]);
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

    it('renders editor when clicking Edit button', async () => {
      createComponent();

      await findEditButton().trigger('click');

      expect(findEditor().exists()).toBe(true);
    });

    it('should show modal when viewing token', async () => {
      createComponent({});

      await findViewButton().trigger('click');

      expect(showModalSpy).toHaveBeenCalled();
      expect(
        wrapper.findComponent('.modal-stub').findComponent(GlFormInputGroup).props('value'),
      ).toBe(mockInstanceExternalDestinations[0].verificationToken);
    });

    describe('when an item has no filter', () => {
      beforeEach(() => {
        createComponent({});
      });

      it('should not show filter badge', () => {
        expect(findFilterBadge().exists()).toBe(false);
      });
    });
  });
});
