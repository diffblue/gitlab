import VueApollo from 'vue-apollo';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import { createAlert } from '~/flash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import externalDestinationsQuery from 'ee/audit_events/graphql/get_external_destinations.query.graphql';
import { AUDIT_STREAMS_NETWORK_ERRORS } from 'ee/audit_events/constants';
import AuditEventsStream from 'ee/audit_events/components/audit_events_stream.vue';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import StreamEmptyState from 'ee/audit_events/components/stream/stream_empty_state.vue';
import {
  mockExternalDestinations,
  groupPath,
  destinationDataPopulator,
  mockSvgPath,
} from '../mock_data';

jest.mock('~/flash');
const localVue = createLocalVue();
localVue.use(VueApollo);

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
      localVue,
    });
  };

  const findAddDestinationButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findStreamDestinationEditor = () => wrapper.findComponent(StreamDestinationEditor);
  const findStreamEmptyState = () => wrapper.findComponent(StreamEmptyState);

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
    });

    it('shows destination editor', async () => {
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findStreamDestinationEditor().exists()).toBe(false);

      await findAddDestinationButton().vm.$emit('click');

      expect(findStreamDestinationEditor().exists()).toBe(true);
    });

    it('refreshes the query and exit edit mode when external destination url added', async () => {
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(externalDestinationsQuerySpy).toHaveBeenCalledTimes(1);
      expect(findStreamDestinationEditor().exists()).toBe(false);

      await findAddDestinationButton().vm.$emit('click');
      const streamDestinationEditorComponent = findStreamDestinationEditor();

      expect(streamDestinationEditorComponent.exists()).toBe(true);

      await streamDestinationEditorComponent.vm.$emit('added');
      await waitForPromises();

      expect(externalDestinationsQuerySpy).toHaveBeenCalledTimes(2);
    });
  });
});
