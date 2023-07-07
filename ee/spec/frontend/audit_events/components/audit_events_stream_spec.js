import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlDisclosureDropdown, GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import externalDestinationsQuery from 'ee/audit_events/graphql/queries/get_external_destinations.query.graphql';
import instanceExternalDestinationsQuery from 'ee/audit_events/graphql/queries/get_instance_external_destinations.query.graphql';
import {
  AUDIT_STREAMS_NETWORK_ERRORS,
  ADD_STREAM_MESSAGE,
  DELETE_STREAM_MESSAGE,
} from 'ee/audit_events/constants';
import AuditEventsStream from 'ee/audit_events/components/audit_events_stream.vue';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import StreamGcpLoggingDestinationEditor from 'ee/audit_events/components/stream/stream_gcp_logging_destination_editor.vue';
import StreamItem from 'ee/audit_events/components/stream/stream_item.vue';
import StreamEmptyState from 'ee/audit_events/components/stream/stream_empty_state.vue';
import {
  mockExternalDestinations,
  groupPath,
  destinationDataPopulator,
  mockInstanceExternalDestinations,
  instanceGroupPath,
  instanceDestinationDataPopulator,
} from '../mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

describe('AuditEventsStream', () => {
  let wrapper;
  let providedGroupPath = groupPath;

  const externalDestinationsQuerySpy = jest
    .fn()
    .mockResolvedValue(destinationDataPopulator(mockExternalDestinations));

  const createComponent = (mockApollo) => {
    wrapper = mountExtended(AuditEventsStream, {
      provide: {
        groupPath: providedGroupPath,
      },
      apolloProvider: mockApollo,
      stubs: {
        GlAlert: true,
        GlLoadingIcon: true,
        StreamItem: true,
        StreamDestinationEditor: true,
        StreamGcpLoggingDestinationEditor: true,
        StreamEmptyState: true,
      },
    });
  };

  const findSuccessMessage = () => wrapper.findComponent(GlAlert);
  const findAddDestinationButton = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDisclosureDropdownItem = (index) =>
    wrapper.findAllComponents(GlDisclosureDropdownItem).at(index).find('button');
  const findHttpDropdownItem = () => findDisclosureDropdownItem(0);
  const findGcpLoggingDropdownItem = () => findDisclosureDropdownItem(1);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStreamDestinationEditor = () => wrapper.findComponent(StreamDestinationEditor);
  const findStreamGcpLoggingDestinationEditor = () =>
    wrapper.findComponent(StreamGcpLoggingDestinationEditor);
  const findStreamEmptyState = () => wrapper.findComponent(StreamEmptyState);
  const findStreamItems = () => wrapper.findAllComponents(StreamItem);

  afterEach(() => {
    createAlert.mockClear();
    externalDestinationsQuerySpy.mockClear();
  });

  describe('Group AuditEventsStream', () => {
    describe('when initialized', () => {
      it('should render the loading icon while waiting for data to be returned', () => {
        const destinationQuerySpy = jest.fn();
        const mockApollo = createMockApollo([[externalDestinationsQuery, destinationQuerySpy]]);
        createComponent(mockApollo);

        expect(findLoadingIcon().exists()).toBe(true);
      });

      it('should render empty state when no data is returned', async () => {
        const destinationQuerySpy = jest.fn().mockResolvedValue(destinationDataPopulator([]));
        const mockApollo = createMockApollo([[externalDestinationsQuery, destinationQuerySpy]]);
        createComponent(mockApollo);
        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(findStreamEmptyState().exists()).toBe(true);
      });

      it('should report error when server error occurred', async () => {
        const destinationQuerySpy = jest.fn().mockRejectedValue({});
        const mockApollo = createMockApollo([[externalDestinationsQuery, destinationQuerySpy]]);
        createComponent(mockApollo);
        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(createAlert).toHaveBeenCalledWith({
          message: AUDIT_STREAMS_NETWORK_ERRORS.FETCHING_ERROR,
        });
      });
    });

    describe('when edit mode entered', () => {
      beforeEach(() => {
        const mockApollo = createMockApollo([
          [externalDestinationsQuery, externalDestinationsQuerySpy],
        ]);
        createComponent(mockApollo);

        return waitForPromises();
      });

      it('shows http destination editor', async () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findStreamDestinationEditor().exists()).toBe(false);

        expect(findAddDestinationButton().props('toggleText')).toBe('Add streaming destination');

        await findHttpDropdownItem().trigger('click');

        expect(findStreamDestinationEditor().exists()).toBe(true);
      });

      it('exits edit mode when an external http destination is added', async () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findStreamDestinationEditor().exists()).toBe(false);

        await findHttpDropdownItem().trigger('click');

        const streamDestinationEditorComponent = findStreamDestinationEditor();

        expect(streamDestinationEditorComponent.exists()).toBe(true);

        streamDestinationEditorComponent.vm.$emit('added');
        await waitForPromises();

        expect(findSuccessMessage().text()).toBe(ADD_STREAM_MESSAGE);
      });

      it('shows http gcp logging editor', async () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findStreamGcpLoggingDestinationEditor().exists()).toBe(false);

        expect(findAddDestinationButton().props('toggleText')).toBe('Add streaming destination');

        await findGcpLoggingDropdownItem().trigger('click');

        expect(findStreamGcpLoggingDestinationEditor().exists()).toBe(true);
      });

      it('exits edit mode when an external gcp logging destination is added', async () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findStreamGcpLoggingDestinationEditor().exists()).toBe(false);

        await findGcpLoggingDropdownItem().trigger('click');

        expect(findStreamGcpLoggingDestinationEditor().exists()).toBe(true);

        findStreamGcpLoggingDestinationEditor().vm.$emit('added');
        await waitForPromises();

        expect(findSuccessMessage().text()).toBe(ADD_STREAM_MESSAGE);
      });

      it('clears the success message if an error occurs afterwards', async () => {
        await findHttpDropdownItem().trigger('click');

        findStreamDestinationEditor().vm.$emit('added');
        await waitForPromises();

        expect(findSuccessMessage().text()).toBe(ADD_STREAM_MESSAGE);

        await findHttpDropdownItem().trigger('click');

        findStreamDestinationEditor().vm.$emit('error');
        await waitForPromises();

        expect(findSuccessMessage().exists()).toBe(false);
      });
    });

    describe('Streaming items', () => {
      beforeEach(() => {
        const mockApollo = createMockApollo([
          [externalDestinationsQuery, externalDestinationsQuerySpy],
        ]);
        createComponent(mockApollo);

        return waitForPromises();
      });

      it('shows the items', () => {
        expect(findStreamItems()).toHaveLength(2);

        expect(findStreamItems().at(0).props('item')).toStrictEqual(mockExternalDestinations[0]);
        expect(findStreamItems().at(1).props('item')).toStrictEqual(mockExternalDestinations[1]);
      });

      it('updates list when destination is removed', async () => {
        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(externalDestinationsQuerySpy).toHaveBeenCalledTimes(1);

        const currentLength = findStreamItems().length;
        findStreamItems().at(0).vm.$emit('deleted');
        await waitForPromises();
        expect(findStreamItems()).toHaveLength(currentLength - 1);
        expect(findSuccessMessage().text()).toBe(DELETE_STREAM_MESSAGE);
      });
    });
  });

  describe('Instance AuditEventsStream', () => {
    beforeEach(() => {
      providedGroupPath = instanceGroupPath;
    });

    const externalInstanceDestinationsQuerySpy = jest
      .fn()
      .mockResolvedValue(instanceDestinationDataPopulator(mockInstanceExternalDestinations));

    afterEach(() => {
      createAlert.mockClear();
      externalInstanceDestinationsQuerySpy.mockClear();
    });

    describe('when initialized', () => {
      it('should render empty state when no data is returned', async () => {
        const instanceDestinationQuerySpy = jest
          .fn()
          .mockResolvedValue(instanceDestinationDataPopulator([]));
        const mockApollo = createMockApollo([
          [instanceExternalDestinationsQuery, instanceDestinationQuerySpy],
        ]);
        createComponent(mockApollo);
        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(findStreamEmptyState().exists()).toBe(true);
      });

      it('should report error when server error occurred', async () => {
        const instanceDestinationQuerySpy = jest.fn().mockRejectedValue({});
        const mockApollo = createMockApollo([
          [instanceExternalDestinationsQuery, instanceDestinationQuerySpy],
        ]);
        createComponent(mockApollo);
        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(createAlert).toHaveBeenCalledWith({
          message: AUDIT_STREAMS_NETWORK_ERRORS.FETCHING_ERROR,
        });
      });
    });

    describe('when edit mode entered', () => {
      beforeEach(() => {
        const mockApollo = createMockApollo([
          [instanceExternalDestinationsQuery, externalInstanceDestinationsQuerySpy],
        ]);
        createComponent(mockApollo);

        return waitForPromises();
      });

      it('shows destination editor', async () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findStreamDestinationEditor().exists()).toBe(false);

        await findHttpDropdownItem().trigger('click');

        expect(findStreamDestinationEditor().exists()).toBe(true);
      });

      it('exits edit mode when an external destination is added', async () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findStreamDestinationEditor().exists()).toBe(false);

        await findHttpDropdownItem().trigger('click');

        expect(findStreamDestinationEditor().exists()).toBe(true);

        findStreamDestinationEditor().vm.$emit('added');
        await waitForPromises();

        expect(findSuccessMessage().text()).toBe(ADD_STREAM_MESSAGE);
      });

      it('clears the success message if an error occurs afterwards', async () => {
        await findHttpDropdownItem().trigger('click');

        findStreamDestinationEditor().vm.$emit('added');
        await waitForPromises();

        expect(findSuccessMessage().text()).toBe(ADD_STREAM_MESSAGE);

        await findHttpDropdownItem().trigger('click');

        findStreamDestinationEditor().vm.$emit('error');
        await waitForPromises();

        expect(findSuccessMessage().exists()).toBe(false);
      });
    });

    describe('Streaming items', () => {
      beforeEach(() => {
        const mockApollo = createMockApollo([
          [instanceExternalDestinationsQuery, externalInstanceDestinationsQuerySpy],
        ]);
        createComponent(mockApollo);

        return waitForPromises();
      });

      it('shows the items', () => {
        expect(findStreamItems()).toHaveLength(2);

        expect(findStreamItems().at(0).props('item')).toStrictEqual(
          mockInstanceExternalDestinations[0],
        );
        expect(findStreamItems().at(1).props('item')).toStrictEqual(
          mockInstanceExternalDestinations[1],
        );
      });

      it('updates list when destination is removed', async () => {
        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(externalInstanceDestinationsQuerySpy).toHaveBeenCalledTimes(1);

        const currentLength = findStreamItems().length;
        findStreamItems().at(0).vm.$emit('deleted');
        await waitForPromises();
        expect(findStreamItems()).toHaveLength(currentLength - 1);
        expect(findSuccessMessage().text()).toBe(DELETE_STREAM_MESSAGE);
      });
    });
  });
});
