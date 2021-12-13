import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Actions, { cancelError } from 'ee/on_demand_scans/components/actions.vue';
import { PIPELINES_GROUP_RUNNING, PIPELINES_GROUP_PENDING } from 'ee/on_demand_scans/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import pipelineCancelMutation from '~/pipelines/graphql/mutations/cancel_pipeline.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

// Dummy scans
const mockPipelineId = 'gid://gitlab/Ci::Pipeline/1';
const runningScan = {
  id: mockPipelineId,
  detailedStatus: {
    group: PIPELINES_GROUP_RUNNING,
  },
};
const pendingScan = {
  id: mockPipelineId,
  detailedStatus: {
    group: PIPELINES_GROUP_PENDING,
  },
};

describe('Actions', () => {
  let wrapper;
  let requestHandler;
  let apolloProvider;

  // Finders
  const findCancelScanButton = () => wrapper.findByTestId('cancel-scan-button');

  // Helpers
  const createMockApolloProvider = (mutation, handler) => {
    requestHandler = handler;
    apolloProvider = createMockApollo([[mutation, handler]]);
  };

  const createComponent = (scan) => {
    wrapper = shallowMountExtended(Actions, {
      apolloProvider,
      propsData: {
        scan,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    requestHandler = null;
    apolloProvider = null;
  });

  it("doesn't render anything if the scan status is not supported", () => {
    createComponent({
      id: mockPipelineId,
      detailedStatus: {
        group: 'foo',
      },
    });

    expect(wrapper.element.childNodes).toHaveLength(1);
    expect(wrapper.element.childNodes[0].tagName).toBeUndefined();
  });

  describe.each`
    scanStatus   | scan
    ${'running'} | ${runningScan}
    ${'pending'} | ${pendingScan}
  `('$scanStatus scan', ({ scan }) => {
    it('renders a cancel button', () => {
      createComponent(scan);
      expect(findCancelScanButton().exists()).toBe(true);
    });

    describe('when clicking on the cancel button', () => {
      let cancelButton;

      beforeEach(() => {
        createMockApolloProvider(
          pipelineCancelMutation,
          jest.fn().mockResolvedValue({ data: { pipelineCancel: { errors: [] } } }),
        );
        createComponent(scan);
        cancelButton = findCancelScanButton();
        cancelButton.vm.$emit('click');
      });

      afterEach(() => {
        cancelButton = null;
      });

      it('trigger the pipelineCancel mutation on click', () => {
        expect(requestHandler).toHaveBeenCalled();
      });

      it('emits the action event and puts the button in the loading state on click', async () => {
        expect(wrapper.emitted('action')).toHaveLength(1);
        expect(cancelButton.props('loading')).toBe(true);
      });
    });

    const errorAsDataMessage = 'Error as data';

    describe.each`
      errorType            | eventPayload                        | handler
      ${'top-level error'} | ${[cancelError, expect.any(Error)]} | ${jest.fn().mockRejectedValue()}
      ${'error as data'}   | ${[errorAsDataMessage, undefined]}  | ${jest.fn().mockResolvedValue({ data: { pipelineCancel: { errors: [errorAsDataMessage] } } })}
    `('on $errorType', ({ eventPayload, handler }) => {
      let cancelButton;

      beforeEach(() => {
        createMockApolloProvider(pipelineCancelMutation, handler);
        createComponent(scan);
        cancelButton = findCancelScanButton();
        cancelButton.vm.$emit('click');
        return waitForPromises();
      });

      afterEach(() => {
        cancelButton = null;
      });

      it('removes the loading state once the mutation errors out', async () => {
        expect(cancelButton.props('loading')).toBe(false);
      });

      it('emits the error', async () => {
        expect(wrapper.emitted('error')).toEqual([eventPayload]);
      });
    });
  });
});
