import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingDetails from 'ee/tracing/components/tracing_details.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrl, isSafeURL } from '~/lib/utils/url_utility';
import TracingDetailsChart from 'ee/tracing/components/tracing_details_chart.vue';
import TracingDetailsHeader from 'ee/tracing/components/tracing_details_header.vue';
import TracingDetailsDrawer from 'ee/tracing/components/tracing_details_drawer.vue';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('TracingDetails', () => {
  let wrapper;
  let observabilityClientMock;

  const TRACE_ID = 'test-trace-id';
  const TRACING_INDEX_URL = 'https://www.gitlab.com/flightjs/Flight/-/tracing';

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const findTraceDetails = () => wrapper.findComponentByTestId('trace-details');
  const findTraceDetailsChart = () => wrapper.findComponent(TracingDetailsChart);

  const findDrawer = () => wrapper.findComponent(TracingDetailsDrawer);
  const isDrawerOpen = () => findDrawer().props('open');
  const getDrawerSpan = () => findDrawer().props('span');

  const props = {
    traceId: TRACE_ID,
    tracingIndexUrl: TRACING_INDEX_URL,
  };

  const mountComponent = async () => {
    wrapper = shallowMountExtended(TracingDetails, {
      propsData: {
        ...props,
        observabilityClient: observabilityClientMock,
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    isSafeURL.mockReturnValue(true);

    observabilityClientMock = {
      isTracingEnabled: jest.fn(),
      fetchTrace: jest.fn(),
    };
  });

  it('renders the loading indicator while checking if tracing is enabled', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
  });

  describe('when tracing is enabled', () => {
    const mockTrace = { traceId: 'test-trace-id', spans: [{ span_id: 'span-1' }] };
    beforeEach(async () => {
      observabilityClientMock.isTracingEnabled.mockResolvedValueOnce(true);
      observabilityClientMock.fetchTrace.mockResolvedValueOnce(mockTrace);

      await mountComponent();
    });

    it('fetches the trace and renders the trace details', () => {
      expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
      expect(observabilityClientMock.fetchTrace).toHaveBeenCalled();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTraceDetails().exists()).toBe(true);
    });

    it('renders the correct components', () => {
      const details = findTraceDetails();
      expect(findTraceDetailsChart().exists()).toBe(true);
      expect(details.findComponent(TracingDetailsHeader).exists()).toBe(true);
    });

    describe('details drawer', () => {
      it('renders the details drawer initially closed', () => {
        expect(findDrawer().exists()).toBe(true);
        expect(isDrawerOpen()).toBe(false);
        expect(getDrawerSpan()).toBe(null);
      });

      const selectSpan = () =>
        findTraceDetailsChart().vm.$emit('span-selected', { spanId: 'span-1' });

      it('opens the drawer and set the selected span, upond selection', async () => {
        await selectSpan();

        expect(isDrawerOpen()).toBe(true);
        expect(getDrawerSpan()).toEqual({ span_id: 'span-1' });
      });

      it('closes the drawer upon receiving the close event', async () => {
        await selectSpan();

        await findDrawer().vm.$emit('close');

        expect(isDrawerOpen()).toBe(false);
        expect(getDrawerSpan()).toBe(null);
      });

      it('closes the drawer on row selection, if drawer is already open', async () => {
        await selectSpan();

        expect(isDrawerOpen()).toBe(true);

        await selectSpan();

        expect(isDrawerOpen()).toBe(false);
      });

      it('set the selected-span-in on the chart component', async () => {
        expect(findTraceDetailsChart().props('selectedSpanId')).toBeNull();
        await selectSpan();
        expect(findTraceDetailsChart().props('selectedSpanId')).toBe('span-1');
      });
    });
  });

  describe('when tracing is not enabled', () => {
    beforeEach(async () => {
      observabilityClientMock.isTracingEnabled.mockResolvedValueOnce(false);

      await mountComponent();
    });

    it('redirects to tracingIndexUrl', () => {
      expect(visitUrl).toHaveBeenCalledWith(props.tracingIndexUrl);
    });
  });

  describe('error handling', () => {
    it('if isTracingEnabled fails, it renders an alert and empty page', async () => {
      observabilityClientMock.isTracingEnabled.mockRejectedValueOnce('error');

      await mountComponent();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to load trace details.' });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTraceDetails().exists()).toBe(false);
    });

    it('if fetchTrace fails, it renders an alert and empty page', async () => {
      observabilityClientMock.isTracingEnabled.mockReturnValueOnce(true);
      observabilityClientMock.fetchTrace.mockRejectedValueOnce('error');

      await mountComponent();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to load trace details.' });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTraceDetails().exists()).toBe(false);
    });
  });
});
