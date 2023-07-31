import { nextTick } from 'vue';
import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { RouterLinkStub } from '@vue/test-utils';
import { GlForm } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import PanelsBase from 'ee/vue_shared/components/customizable_dashboard/panels_base.vue';
import DateRangeFilter from 'ee/vue_shared/components/customizable_dashboard/filters/date_range_filter.vue';
import {
  GRIDSTACK_MARGIN,
  GRIDSTACK_CSS_HANDLE,
  GRIDSTACK_CELL_HEIGHT,
  GRIDSTACK_MIN_ROW,
  NEW_DASHBOARD_SLUG,
} from 'ee/vue_shared/components/customizable_dashboard/constants';
import { loadCSSFile } from '~/lib/utils/css_utils';
import waitForPromises from 'helpers/wait_for_promises';
import {
  filtersToQueryParams,
  buildDefaultDashboardFilters,
} from 'ee/vue_shared/components/customizable_dashboard/utils';
import UrlSync, { HISTORY_REPLACE_UPDATE_METHOD } from '~/vue_shared/components/url_sync.vue';
import VisualizationSelector from 'ee/vue_shared/components/customizable_dashboard/dashboard_editor/visualization_selector.vue';
import { NEW_DASHBOARD } from 'ee/analytics/analytics_dashboards/constants';
import { TEST_VISUALIZATION } from 'ee_jest/analytics/analytics_dashboards/mock_data';
import { dashboard, builtinDashboard, mockDateRangeFilterChangePayload } from './mock_data';

jest.mock('gridstack', () => ({
  GridStack: {
    init: jest.fn(() => {
      return {
        on: jest.fn(),
        destroy: jest.fn(),
        makeWidget: jest.fn(),
        setStatic: jest.fn(),
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

  const $router = {
    push: jest.fn(),
  };

  const createWrapper = (
    props = {},
    loadedDashboard = dashboard,
    provide = {},
    routeParams = {},
  ) => {
    const loadDashboard = { ...loadedDashboard };

    wrapper = shallowMountExtended(CustomizableDashboard, {
      propsData: {
        initialDashboard: loadDashboard,
        availableVisualizations: {},
        ...props,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
      mocks: {
        $router,
        $route: {
          params: routeParams,
        },
      },
      provide,
    });
  };

  const findGridStackPanels = () => wrapper.findAllByTestId('grid-stack-panel');
  const findPanels = () => wrapper.findAllComponents(PanelsBase);
  const findEditButton = () => wrapper.findByTestId('dashboard-edit-btn');
  const findDashboardTB = () => wrapper.findByTestId('dashboard-title-tb');
  const findSaveButton = () => wrapper.findByTestId('dashboard-save-btn');
  const findCancelEditButton = () => wrapper.findByTestId('dashboard-cancel-edit-btn');
  const findCodeButton = () => wrapper.findByTestId('dashboard-code-btn');
  const findCodeView = () => wrapper.findByTestId('dashboard-code');
  const findFilters = () => wrapper.findByTestId('dashboard-filters');
  const findDateRangeFilter = () => wrapper.findComponent(DateRangeFilter);
  const findUrlSync = () => wrapper.findComponent(UrlSync);
  const findForm = () => wrapper.findComponent(GlForm);
  const findVisualizationSelector = () => wrapper.findComponent(VisualizationSelector);

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

  describe('when mounted updates', () => {
    let wrapperLimited;
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      wrapperLimited = document.createElement('div');
      wrapperLimited.classList.add('container-fluid', 'container-limited');
      document.body.appendChild(wrapperLimited);

      createWrapper();
    });

    afterEach(() => {
      document.body.removeChild(wrapperLimited);
    });

    it('body container', () => {
      expect(document.querySelectorAll('.container-fluid.not-container-limited').length).toBe(1);
    });

    it('body container after destroy', () => {
      wrapper.destroy();

      expect(document.querySelectorAll('.container-fluid.not-container-limited').length).toBe(0);
      expect(document.querySelectorAll('.container-fluid.container-limited').length).toBe(1);
    });
  });

  describe('when mounted', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper();
    });

    it('sets up GridStack', () => {
      expect(GridStack.init).toHaveBeenCalledWith({
        alwaysShowResizeHandle: true,
        staticGrid: true,
        margin: GRIDSTACK_MARGIN,
        handle: GRIDSTACK_CSS_HANDLE,
        cellHeight: GRIDSTACK_CELL_HEIGHT,
        minRow: GRIDSTACK_MIN_ROW,
      });
    });

    it.each(
      dashboard.panels.map((panel, index) => [
        panel.title,
        panel.visualization,
        panel.gridAttributes,
        panel.queryOverrides,
        index,
      ]),
    )(
      'should render the panel for %s',
      (title, visualization, gridAttributes, queryOverrides, index) => {
        expect(findPanels().at(index).props()).toMatchObject({
          title,
          visualization,
          // The panel component defaults `queryOverrides` to {} when falsy
          queryOverrides: queryOverrides || {},
        });

        expect(findGridStackPanels().at(index).attributes()).toMatchObject({
          'gs-id': `${index}`,
          'gs-h': `${gridAttributes.height}`,
          'gs-w': `${gridAttributes.width}`,
        });
      },
    );

    it('does not show the Edit Button for a custom dashboard', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    it('does not show the filters', () => {
      expect(findFilters().exists()).toBe(false);
    });

    it('does not sync filters with the URL', () => {
      expect(findUrlSync().exists()).toBe(false);
    });
  });

  describe('beforeDestroy', () => {
    beforeEach(() => {
      createWrapper();
    });
  });

  describe('when builtin Dashboard is loaded', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper({}, builtinDashboard);
    });

    it('shows no Edit Button for a builtin dashboard', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    it('shows Code Button', () => {
      expect(findCodeButton().exists()).toBe(true);
    });
  });

  describe('when the combinedAnalyticsDashboardsEditor feature flag is enabled on a custom dashboard', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper({}, dashboard, { glFeatures: { combinedAnalyticsDashboardsEditor: true } });
    });

    it('shows the Edit Button', () => {
      expect(findEditButton().exists()).toBe(true);
    });

    describe('when mounted with the $route.editing param', () => {
      beforeEach(() => {
        createWrapper(
          {},
          dashboard,
          { glFeatures: { combinedAnalyticsDashboardsEditor: true } },
          { editing: true },
        );
      });

      it('opens the dashboard in edit mode', () => {
        expect(findVisualizationSelector().exists()).toBe(true);
      });
    });

    describe('when editing', () => {
      beforeEach(() => {
        findEditButton().vm.$emit('click');
      });

      it('shows the Save button', () => {
        expect(findSaveButton().attributes('type')).toBe('submit');
        expect(findSaveButton().props('loading')).toBe(false);
      });

      it('shows Code Button', () => {
        expect(findCodeButton().exists()).toBe(true);
      });

      it('updates panels when their values change', async () => {
        await wrapper.vm.updatePanelWithGridStackItem({ id: '0', x: 10, y: 20, w: 30, h: 40 });

        expect(findGridStackPanels().at(0).attributes()).toMatchObject({
          id: 'panel-0',
          'gs-h': '40',
          'gs-w': '30',
          'gs-x': '10',
          'gs-y': '20',
        });
      });

      it('shows an input element with the title as value', () => {
        expect(findDashboardTB().attributes()).toMatchObject({
          value: 'Analytics Overview',
          required: '',
        });
      });

      it('saves the dashboard changes when the form is submitted', async () => {
        await findDashboardTB().vm.$emit('input', 'New Title');

        await findForm().vm.$emit('submit', new Event('submit'));

        expect(wrapper.emitted('save')).toMatchObject([
          [
            'analytics_overview',
            {
              ...dashboard,
              title: 'New Title',
            },
          ],
        ]);
      });

      it('clicking Code Button will show code', async () => {
        await findCodeButton().vm.$emit('click');

        expect(findCodeView().exists()).toBe(true);
      });

      it('clicking twice on Code Button will show dashboard', async () => {
        await findCodeButton().vm.$emit('click');
        await findCodeButton().vm.$emit('click');

        expect(findCodeView().exists()).toBe(false);
      });

      it('shows Cancel Edit Button', () => {
        expect(findCancelEditButton().exists()).toBe(true);
      });

      it('shows no Edit Button', () => {
        expect(findEditButton().exists()).toBe(false);
      });

      it('shows the visualization selector', () => {
        expect(findVisualizationSelector().props()).toMatchObject({
          availableVisualizations: {},
        });
      });

      it('add a new panel when a visualization is selected', async () => {
        expect(findPanels()).toHaveLength(2);

        const visualization = TEST_VISUALIZATION();
        await findVisualizationSelector().vm.$emit('select', visualization);
        await nextTick();

        const updatedPanels = findPanels();
        expect(updatedPanels).toHaveLength(3);
        expect(updatedPanels.at(-1).props('visualization')).toMatchObject(visualization);
      });

      it('routes to the designer when a "create" event is received', async () => {
        await findVisualizationSelector().vm.$emit('create');

        expect($router.push).toHaveBeenCalledWith({
          name: 'visualization-designer',
          params: {
            dashboard: dashboard.slug,
          },
        });
      });
    });
  });

  describe('when the date range filter is enabled and configured', () => {
    const defaultFilters = buildDefaultDashboardFilters('');

    describe('by default', () => {
      beforeEach(() => {
        loadCSSFile.mockResolvedValue();

        createWrapper({ showDateRangeFilter: true, syncUrlFilters: true, defaultFilters });
      });

      it('shows the date range filter and passes the default options and filters', () => {
        expect(findDateRangeFilter().props()).toMatchObject({
          startDate: defaultFilters.startDate,
          endDate: defaultFilters.endDate,
          defaultOption: defaultFilters.dateRangeOption,
          dateRangeLimit: 0,
        });
      });

      it('synchronizes the filters with the URL', () => {
        expect(findUrlSync().props()).toMatchObject({
          historyUpdateMethod: HISTORY_REPLACE_UPDATE_METHOD,
          query: filtersToQueryParams(defaultFilters),
        });
      });

      it('sets the panel filters to the default date range', () => {
        expect(findPanels().at(0).props().filters).toStrictEqual(defaultFilters);
      });

      it('updates the panel filters when the date range is changed', async () => {
        await findDateRangeFilter().vm.$emit('change', mockDateRangeFilterChangePayload);

        expect(findPanels().at(0).props().filters).toStrictEqual(mockDateRangeFilterChangePayload);
      });
    });

    describe.each([0, 12, 31])('when given a date range limit of %d', (dateRangeLimit) => {
      beforeEach(() => {
        loadCSSFile.mockResolvedValue();

        createWrapper({
          showDateRangeFilter: true,
          syncUrlFilters: true,
          defaultFilters,
          dateRangeLimit,
        });
      });

      it('passes the date range limit to the date range filter', () => {
        expect(findDateRangeFilter().props()).toMatchObject({
          dateRangeLimit,
        });
      });
    });
  });

  describe('when a dashboard is new', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper(
        {
          isNewDashboard: true,
        },
        NEW_DASHBOARD(),
      );
    });

    it('does not render the cancel button', () => {
      expect(findCancelEditButton().exists()).toBe(false);
    });

    it('renders the router link', () => {
      expect(wrapper.findComponent(RouterLinkStub).exists()).toBe(true);
    });

    it('reverts to the preview view when saving', async () => {
      await findCodeButton().vm.$emit('click');

      expect(findCodeView().exists()).toBe(true);

      await findForm().vm.$emit('submit', new Event('submit'));

      expect(findCodeView().exists()).toBe(false);
    });

    it('routes to the designer with `dashboard: "new"` when a "create" event is recieved', async () => {
      await findVisualizationSelector().vm.$emit('create');

      expect($router.push).toHaveBeenCalledWith({
        name: 'visualization-designer',
        params: {
          dashboard: NEW_DASHBOARD_SLUG,
        },
      });
    });

    it('generates a slug for the dashboard when saving', async () => {
      const title = 'New Title';
      const expectedSlug = 'new_title';
      await findDashboardTB().vm.$emit('input', title);

      await findForm().vm.$emit('submit', new Event('submit'));

      expect(wrapper.emitted('save')).toMatchObject([
        [expectedSlug, { title, panels: [], userDefined: true }],
      ]);
    });
  });

  describe('when saving while editing and the editor is enabled', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper({ isSaving: true }, dashboard, {
        glFeatures: { combinedAnalyticsDashboardsEditor: true },
      });

      findEditButton().vm.$emit('click');
    });

    it('shows the Save button as loading', () => {
      expect(findSaveButton().props('loading')).toBe(true);
    });
  });
});
