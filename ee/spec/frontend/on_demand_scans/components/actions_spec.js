import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Actions, { cancelError, retryError } from 'ee/on_demand_scans/components/actions.vue';
import {
  PIPELINES_GROUP_RUNNING,
  PIPELINES_GROUP_PENDING,
  PIPELINES_GROUP_SUCCESS_WITH_WARNINGS,
  PIPELINES_GROUP_FAILED,
  PIPELINES_GROUP_SUCCESS,
} from 'ee/on_demand_scans/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import pipelineCancelMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import pipelineRetryMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

// Dummy scans
const mockPipelineId = 'gid://gitlab/Ci::Pipeline/1';
const scanFactory = (group) => ({
  id: mockPipelineId,
  detailedStatus: {
    group,
  },
  path: '/pipelines/1',
});
const runningScan = scanFactory(PIPELINES_GROUP_RUNNING);
const pendingScan = scanFactory(PIPELINES_GROUP_PENDING);
const successWithWarningsScan = scanFactory(PIPELINES_GROUP_SUCCESS_WITH_WARNINGS);
const failedScan = scanFactory(PIPELINES_GROUP_FAILED);
const succeededScan = scanFactory(PIPELINES_GROUP_SUCCESS);
const scheduledScan = {
  id: mockPipelineId,
  editPath: '/edit/1',
};

// Error messages
const errorAsDataMessage = 'Error as data';

describe('Actions', () => {
  let wrapper;
  let requestHandler;
  let apolloProvider;

  // Finders
  const findCancelScanButton = () => wrapper.findByTestId('cancel-scan-button');
  const findRetryScanButton = () => wrapper.findByTestId('retry-scan-button');
  const findEditScanButton = () => wrapper.findByTestId('edit-scan-button');
  const findViewScanResultsButton = () => wrapper.findByTestId('view-scan-results-button');

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

    expect(wrapper.element).toMatchSnapshot();
  });

  describe.each`
    scanStatus                 | scan                       | buttonFinder            | mutation                  | mutationType        | errorMessage
    ${'running'}               | ${runningScan}             | ${findCancelScanButton} | ${pipelineCancelMutation} | ${'pipelineCancel'} | ${cancelError}
    ${'pending'}               | ${pendingScan}             | ${findCancelScanButton} | ${pipelineCancelMutation} | ${'pipelineCancel'} | ${cancelError}
    ${'success with warnings'} | ${successWithWarningsScan} | ${findRetryScanButton}  | ${pipelineRetryMutation}  | ${'pipelineRetry'}  | ${retryError}
    ${'failed'}                | ${failedScan}              | ${findRetryScanButton}  | ${pipelineRetryMutation}  | ${'pipelineRetry'}  | ${retryError}
  `('$scanStatus scan', ({ scan, buttonFinder, mutation, mutationType, errorMessage }) => {
    it('renders the action button', () => {
      createComponent(scan);
      expect(buttonFinder().exists()).toBe(true);
    });

    describe('when clicking on the button', () => {
      let button;

      beforeEach(() => {
        createMockApolloProvider(
          mutation,
          jest.fn().mockResolvedValue({ data: { [mutationType]: { errors: [] } } }),
        );
        createComponent(scan);
        button = buttonFinder();
        button.vm.$emit('click');
      });

      afterEach(() => {
        button = null;
      });

      it(`triggers the ${mutationType} mutation on click`, () => {
        expect(requestHandler).toHaveBeenCalled();
      });

      it('emits the action event and puts the button in the loading state on click', () => {
        expect(wrapper.emitted('action')).toHaveLength(1);
        expect(button.props('isLoading')).toBe(true);
      });
    });

    describe.each`
      errorType            | eventPayload                         | handler
      ${'top-level error'} | ${[errorMessage, expect.any(Error)]} | ${jest.fn().mockRejectedValue()}
      ${'error as data'}   | ${[errorAsDataMessage, undefined]}   | ${jest.fn().mockResolvedValue({ data: { [mutationType]: { errors: [errorAsDataMessage] } } })}
    `('on $errorType', ({ eventPayload, handler }) => {
      let button;

      beforeEach(() => {
        createMockApolloProvider(mutation, handler);
        createComponent(scan);
        button = buttonFinder();
        button.vm.$emit('click');
        return waitForPromises();
      });

      afterEach(() => {
        button = null;
      });

      it('removes the loading state once the mutation errors out', () => {
        expect(button.props('isLoading')).toBe(false);
      });

      it('emits the error', () => {
        expect(wrapper.emitted('error')).toEqual([eventPayload]);
      });
    });
  });

  it('renders an edit link for scheduled scans', () => {
    createComponent(scheduledScan);
    const editButton = findEditScanButton();

    expect(editButton.exists()).toBe(true);
    expect(editButton.attributes('href')).toBe(scheduledScan.editPath);
  });

  it.each`
    scanStatus                 | scan
    ${'success with warnings'} | ${successWithWarningsScan}
    ${'failed'}                | ${failedScan}
    ${'succeeded'}             | ${succeededScan}
  `('renders a "View results" button for $scanStatus scans', ({ scan }) => {
    createComponent(scan);
    const viewScanResultsButton = findViewScanResultsButton();

    expect(viewScanResultsButton.exists()).toBe(true);
    expect(viewScanResultsButton.attributes('href')).toBe(`${scan.path}/security`);
  });
});
