import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { RouterLinkStub } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import PanelsBase from 'ee/vue_shared/components/customizable_dashboard/panels_base.vue';
import DateRangeFilter from 'ee/vue_shared/components/customizable_dashboard/filters/date_range_filter.vue';
import {
  GRIDSTACK_MARGIN,
  GRIDSTACK_CSS_HANDLE,
} from 'ee/vue_shared/components/customizable_dashboard/constants';
import { loadCSSFile } from '~/lib/utils/css_utils';
import { createAlert } from '~/flash';
import waitForPromises from 'helpers/wait_for_promises';
import { dashboard } from './mock_data';

jest.mock('~/flash');
jest.mock('gridstack', () => ({
  GridStack: {
    init: jest.fn(() => {
      return {
        on: jest.fn(),
        destroy: jest.fn(),
      };
    }),
  },
}));

jest.mock('~/lib/utils/css_utils', () => ({
  loadCSSFile: jest.fn(),
}));

describe('CustomizableDashboard', () => {
  let wrapper;

  const sentryError = new Error('Network error');

  const createWrapper = (props = {}) => {
    dashboard.default = { ...dashboard };

    wrapper = shallowMountExtended(CustomizableDashboard, {
      propsData: {
        initialDashboard: dashboard,
        availableVisualizations: [],
        ...props,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
    });
  };

  const findGridStackPanels = () => wrapper.findAllByTestId('grid-stack-panel');
  const findPanels = () => wrapper.findAllComponents(PanelsBase);
  const findEditButton = () => wrapper.findByTestId('dashboard-edit-btn');
  const findCancelEditButton = () => wrapper.findByTestId('dashboard-cancel-edit-btn');
  const findCodeButton = () => wrapper.findByTestId('dashboard-code-btn');
  const findFilters = () => wrapper.findByTestId('dashboard-filters');
  const findDateRangeFilter = () => wrapper.findComponent(DateRangeFilter);

  describe('when being created an error occurs while loading the CSS', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      loadCSSFile.mockRejectedValue(sentryError);

      createWrapper();
    });

    it('reports the error to sentry', async () => {
      await waitForPromises();
      expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(sentryError);
    });
  });

  describe('when mounted', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper();
    });

    it('sets up GridStack', () => {
      expect(GridStack.init).toHaveBeenCalledWith({
        staticGrid: true,
        margin: GRIDSTACK_MARGIN,
        minRow: 1,
        handle: GRIDSTACK_CSS_HANDLE,
      });
    });

    it.each(
      dashboard.panels.map((panel, index) => [
        panel.id,
        panel.title,
        panel.visualization,
        panel.gridAttributes,
        panel.queryOverrides,
        index,
      ]),
    )(
      'should render the panel for %s',
      (id, title, visualization, gridAttributes, queryOverrides, index) => {
        expect(findPanels().at(index).props()).toMatchObject({
          title,
          visualization,
          queryOverrides,
        });

        expect(findGridStackPanels().at(index).attributes()).toMatchObject({
          'gs-id': `${id}`,
          'gs-h': `${gridAttributes.height}`,
          'gs-w': `${gridAttributes.width}`,
        });
      },
    );

    it('calls createAlert when a panel emits an error', () => {
      const error = new Error('foo');

      findPanels().at(0).vm.$emit('error', error);

      expect(createAlert).toHaveBeenCalledWith({
        message: `An error occured while loading the ${dashboard.panels[0].title} panel.`,
        captureError: true,
        error,
      });
    });

    it('shows Edit Button', () => {
      expect(findEditButton().exists()).toBe(true);
    });

    it('does not show the filters', () => {
      expect(findFilters().exists()).toBe(false);
    });
  });

  describe('when editing', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper();

      findEditButton().vm.$emit('click');
    });

    it('shows Code Button', () => {
      expect(wrapper.vm.editing).toBe(true);
      expect(findCodeButton().exists()).toBe(true);
    });

    it('updates panels when their values change', async () => {
      await wrapper.vm.updatePanelWithGridStackItem({ id: 1, x: 10, y: 20, w: 30, h: 40 });

      expect(findGridStackPanels().at(0).attributes()).toMatchObject({
        id: 'panel-1',
        'gs-h': '40',
        'gs-w': '30',
        'gs-x': '10',
        'gs-y': '20',
      });
    });

    it('clicking Code Button will show code', async () => {
      await findCodeButton().vm.$emit('click');

      expect(wrapper.vm.showCode).toBe(true);
      expect(wrapper.findByTestId('dashboard-code').exists()).toBe(true);
    });

    it('clicking twice on Code Button will show dashboard', async () => {
      await findCodeButton().vm.$emit('click');
      await findCodeButton().vm.$emit('click');

      expect(wrapper.vm.showCode).toBe(false);
      expect(wrapper.findByTestId('dashboard-code').exists()).toBe(false);
    });

    it('shows Cancel Edit Button', () => {
      expect(findCancelEditButton().exists()).toBe(true);
    });

    it('shows no Edit Button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('when the date range filter is enabled and configured', () => {
    const defaultFilters = {
      dateRange: {
        startDate: new Date('2015-01-01'),
        endDate: new Date('2015-02-01'),
      },
    };

    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper({ showDateRangeFilter: true, defaultFilters });
    });

    it('shows the date range filter and passes the default options and filters', () => {
      expect(findDateRangeFilter().props()).toMatchObject({
        startDate: defaultFilters.dateRange.startDate,
        endDate: defaultFilters.dateRange.endDate,
      });
    });

    it('sets the panel filters to the default date range', () => {
      expect(findPanels().at(0).props().filters).toStrictEqual(defaultFilters);
    });

    it('updates the panel filters when the date range is changed', async () => {
      const startDate = new Date('2016-01-01');
      const endDate = new Date('2016-02-01');

      await findDateRangeFilter().vm.$emit('change', { startDate, endDate });

      expect(findPanels().at(0).props().filters).toStrictEqual({
        dateRange: { startDate, endDate },
      });
    });
  });
});
