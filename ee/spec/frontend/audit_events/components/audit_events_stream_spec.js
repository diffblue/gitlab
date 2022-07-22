import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import externalDestinationsQuery from 'ee/audit_events/graphql/get_external_destinations.query.graphql';
import { AUDIT_STREAMS_NETWORK_ERRORS } from 'ee/audit_events/constants';
import AuditEventsStream from 'ee/audit_events/components/audit_events_stream.vue';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import StreamItem from 'ee/audit_events/components/stream/stream_item.vue';
import StreamEmptyState from 'ee/audit_events/components/stream/stream_empty_state.vue';
import {
  mockExternalDestinations,
  groupPath,
  destinationDataPopulator,
  mockSvgPath,
} from '../mock_data';

jest.mock('~/flash');
Vue.use(VueApollo);

describe('AuditEventsStream', () => {
  let wrapper;

  const externalDestinationsQuerySpy = jest
    .fn()
    .mockResolvedValue(destinationDataPopulator(mockExternalDestinations));

  const createComponent = (destinationQuerySpy = externalDestinationsQuerySpy) => {
    const mockApollo = createMockApollo([[externalDestinationsQuery, destinationQuerySpy]]);
    wrapper = shallowMountExtended(AuditEventsStream, {
      provide: {
        groupPath,
        streamsIconSvgPath: mockSvgPath,
      },
      apolloProvider: mockApollo,
    });
  };

  const findAddDestinationButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStreamDestinationEditor = () => wrapper.findComponent(StreamDestinationEditor);
  const findStreamEmptyState = () => wrapper.findComponent(StreamEmptyState);
  const findStreamItems = () => wrapper.findAllComponents(StreamItem);

  afterEach(() => {
    wrapper.destroy();
    createAlert.mockClear();
    externalDestinationsQuerySpy.mockClear();
  });

  describe('when initialized', () => {
    it('should render the loading icon while waiting for data to be returned', () => {
      const destinationQuerySpy = jest.fn();
      createComponent(destinationQuerySpy);

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('should render empty state when no data is returned', async () => {
      const destinationQuerySpy = jest.fn().mockResolvedValue(destinationDataPopulator([]));
      createComponent(destinationQuerySpy);
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findStreamEmptyState().exists()).toBe(true);
    });

    it('should report error when server error occurred', async () => {
      const destinationQuerySpy = jest.fn().mockRejectedValue({});
      createComponent(destinationQuerySpy);
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(createAlert).toHaveBeenCalledWith({
        message: AUDIT_STREAMS_NETWORK_ERRORS.FETCHING_ERROR,
      });
    });
  });

  describe('when edit mode entered', () => {
    beforeEach(() => {
      createComponent();

      return waitForPromises();
    });

    it('shows destination editor', async () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findStreamDestinationEditor().exists()).toBe(false);

      findAddDestinationButton().vm.$emit('click');
      await nextTick();

      expect(findStreamDestinationEditor().exists()).toBe(true);
    });

    it('refreshes the query and exits edit mode when an external destination is added', async () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(externalDestinationsQuerySpy).toHaveBeenCalledTimes(1);
      expect(findStreamDestinationEditor().exists()).toBe(false);

      findAddDestinationButton().vm.$emit('click');
      await nextTick();

      const streamDestinationEditorComponent = findStreamDestinationEditor();

      expect(streamDestinationEditorComponent.exists()).toBe(true);

      streamDestinationEditorComponent.vm.$emit('added');
      await waitForPromises();

      expect(externalDestinationsQuerySpy).toHaveBeenCalledTimes(2);
    });
  });

  describe('Streaming items', () => {
    beforeEach(() => {
      createComponent();

      return waitForPromises();
    });

    it('shows the items', () => {
      expect(findStreamItems()).toHaveLength(2);

      expect(findStreamItems().at(0).props('item')).toStrictEqual(mockExternalDestinations[0]);
      expect(findStreamItems().at(1).props('item')).toStrictEqual(mockExternalDestinations[1]);
    });

    it.each(['updated', 'deleted'])(
      'refreshes the query when an external destination is %s',
      async (eventName) => {
        await waitForPromises();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(externalDestinationsQuerySpy).toHaveBeenCalledTimes(1);

        findStreamItems().at(0).vm.$emit(eventName);
        await waitForPromises();

        expect(externalDestinationsQuerySpy).toHaveBeenCalledTimes(2);
      },
    );
  });
});
