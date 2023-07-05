import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { STREAM_ITEMS_I18N } from 'ee/audit_events/constants';
import StreamItem from 'ee/audit_events/components/stream/stream_item.vue';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import StreamGcpLoggingDestinationEditor from 'ee/audit_events/components/stream/stream_gcp_logging_destination_editor.vue';
import {
  groupPath,
  mockExternalDestinations,
  instanceGroupPath,
  mockInstanceExternalDestinations,
  mockHttpType,
  mockGcpLoggingType,
} from '../../mock_data';

describe('StreamItem', () => {
  let wrapper;

  const destinationWithoutFilters = mockExternalDestinations[0];
  const destinationWithFilters = mockExternalDestinations[1];
  const instanceDestination = mockInstanceExternalDestinations[0];

  let groupPathProvide = groupPath;
  let itemProps = destinationWithoutFilters;
  let typeProps = mockHttpType;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(StreamItem, {
      propsData: {
        item: itemProps,
        type: typeProps,
        ...props,
      },
      provide: {
        groupPath: groupPathProvide,
      },
      stubs: {
        StreamDestinationEditor: true,
      },
    });
  };

  const findToggleButton = () => wrapper.findByTestId('toggle-btn');
  const findEditor = () => wrapper.findComponent(StreamDestinationEditor);
  const findGcpLoggingEditor = () => wrapper.findComponent(StreamGcpLoggingDestinationEditor);
  const findFilterBadge = () => wrapper.findByTestId('filter-badge');

  describe('Group http StreamItem', () => {
    describe('render', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should not render the editor', () => {
        expect(findEditor().exists()).toBe(false);
      });
    });

    describe('deleting', () => {
      const id = 1;

      it('bubbles up the "deleted" event', async () => {
        createComponent();
        await findToggleButton().vm.$emit('click');

        findEditor().vm.$emit('deleted', id);

        expect(wrapper.emitted('deleted')).toEqual([[id]]);
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

  describe('Group gcp logging StreamItem', () => {
    beforeEach(() => {
      typeProps = mockGcpLoggingType;
    });

    describe('render', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should not render the editor', () => {
        expect(findGcpLoggingEditor().exists()).toBe(false);
      });
    });

    describe('deleting', () => {
      const id = 1;

      it('bubbles up the "deleted" event', async () => {
        createComponent();
        await findToggleButton().vm.$emit('click');

        findGcpLoggingEditor().vm.$emit('deleted', id);

        expect(wrapper.emitted('deleted')).toEqual([[id]]);
      });
    });

    describe('editing', () => {
      beforeEach(async () => {
        createComponent();
        await findToggleButton().vm.$emit('click');
      });

      it('should pass the item to the editor', () => {
        expect(findGcpLoggingEditor().exists()).toBe(true);
        expect(findGcpLoggingEditor().props('item')).toStrictEqual(mockExternalDestinations[0]);
      });

      it('should emit the updated event when the editor fires its update event', async () => {
        findGcpLoggingEditor().vm.$emit('updated');
        await waitForPromises();

        expect(wrapper.emitted('updated')).toBeDefined();

        expect(findGcpLoggingEditor().exists()).toBe(false);
      });

      it('should emit the error event when the editor fires its error event', () => {
        findGcpLoggingEditor().vm.$emit('error');

        expect(wrapper.emitted('error')).toBeDefined();
        expect(findGcpLoggingEditor().exists()).toBe(true);
      });

      it('should close the editor when the editor fires its cancel event', async () => {
        findGcpLoggingEditor().vm.$emit('cancel');
        await waitForPromises();

        expect(findGcpLoggingEditor().exists()).toBe(false);
      });
    });
  });

  describe('Instance StreamItem', () => {
    beforeEach(() => {
      groupPathProvide = instanceGroupPath;
      itemProps = instanceDestination;
      typeProps = mockHttpType;
    });

    describe('render', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should not render the editor', () => {
        expect(findEditor().exists()).toBe(false);
      });
    });

    describe('deleting', () => {
      const id = 1;

      it('bubbles up the "deleted" event', async () => {
        createComponent();
        await findToggleButton().vm.$emit('click');

        findEditor().vm.$emit('deleted', id);

        expect(wrapper.emitted('deleted')).toEqual([[id]]);
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
