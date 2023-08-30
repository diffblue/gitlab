import { nextTick } from 'vue';
import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { RouterLinkStub } from '@vue/test-utils';
import { GlEmptyState, GlLink } from '@gitlab/ui';
import { createAlert } from '~/alert';
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
import {
  TEST_VISUALIZATION,
  TEST_EMPTY_DASHBOARD_SVG_PATH,
} from 'ee_jest/analytics/analytics_dashboards/mock_data';
import { dashboard, builtinDashboard, mockDateRangeFilterChangePayload } from './mock_data';

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

const mockGridSetStatic = jest.fn();
jest.mock('gridstack', () => ({
  GridStack: {
    init: jest.fn(() => {
      return {
        on: jest.fn(),
        destroy: jest.fn(),
        makeWidget: jest.fn(),
        setStatic: mockGridSetStatic,
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
      provide: {
        dashboardEmptyStateIllustrationPath: TEST_EMPTY_DASHBOARD_SVG_PATH,
        ...provide,
      },
    });
  };

  const findGrid = () => wrapper.findByTestId('gridstack-grid');
  const findDashboardTitle = () => wrapper.findByTestId('dashboard-title');
  const findEditModeTitle = () => wrapper.findByTestId('edit-mode-title');
  const findGridStackPanels = () => wrapper.findAllByTestId('grid-stack-panel');
  const findPanels = () => wrapper.findAllComponents(PanelsBase);
  const findEditButton = () => wrapper.findByTestId('dashboard-edit-btn');
  const findTitleInput = () => wrapper.findByTestId('dashboard-title-input');
  const findTitleFormGroup = () => wrapper.findByTestId('dashboard-title-form-group');
  const findSaveButton = () => wrapper.findByTestId('dashboard-save-btn');
  const findCancelButton = () => wrapper.findByTestId('dashboard-cancel-edit-btn');
  const findFilters = () => wrapper.findByTestId('dashboard-filters');
  const findDateRangeFilter = () => wrapper.findComponent(DateRangeFilter);
  const findUrlSync = () => wrapper.findComponent(UrlSync);
  const findVisualizationSelector = () => wrapper.findComponent(VisualizationSelector);
  const findDashboardDescription = () => wrapper.findByTestId('dashboard-description');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('when being created and an error occurs while loading the CSS', () => {
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

  describe('default behaviour', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper({}, dashboard);
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

    it('shows the dashboard title', () => {
      expect(findDashboardTitle().text()).toBe('Analytics Overview');
    });

    it('does not show the edit mode page title', () => {
      expect(findEditModeTitle().exists()).toBe(false);
    });

    it('does not show the "edit" or "cancel" button', () => {
      expect(findEditButton().exists()).toBe(false);
      expect(findCancelButton().exists()).toBe(false);
    });

    it('does not show the title input', () => {
      expect(findTitleInput().exists()).toBe(false);
    });

    it('does not show the filters', () => {
      expect(findFilters().exists()).toBe(false);
    });

    it('does not sync filters with the URL', () => {
      expect(findUrlSync().exists()).toBe(false);
    });

    it('does not show a dashboard description', () => {
      expect(findDashboardDescription().exists()).toBe(false);
    });
  });

  describe('when the dashboard has a description loaded', () => {
    const description = 'This is a description of the greatest dashboard';
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();
    });

    it('shows the dashboard description', () => {
      createWrapper({}, { ...builtinDashboard, description });

      expect(findDashboardDescription().text()).toBe(description);
    });

    it('does not show a dashboard documentation link', () => {
      createWrapper({}, { ...builtinDashboard, description });

      expect(findDashboardDescription().findComponent(GlLink).exists()).toBe(false);
    });

    describe('when a documentation link exists', () => {
      it('shows the dashboard documentation link', () => {
        createWrapper({}, { ...builtinDashboard, description, slug: 'value_stream_dashboard' });

        expect(findDashboardDescription().findComponent(GlLink).attributes('href')).toBe(
          '/help/user/analytics/value_streams_dashboard',
        );
      });
    });
  });

  describe('when the combinedAnalyticsDashboardsEditor feature flag is enabled', () => {
    describe('with a built-in dashboard', () => {
      beforeEach(() => {
        loadCSSFile.mockResolvedValue();

        createWrapper({}, builtinDashboard, {
          glFeatures: { combinedAnalyticsDashboardsEditor: true },
        });
      });

      it('does not show the edit button', () => {
        expect(findEditButton().exists()).toBe(false);
      });
    });

    describe('with a custom dashboard', () => {
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

        it('sets the grid to non-static mode', () => {
          expect(mockGridSetStatic).toHaveBeenCalledWith(false);
        });

        it('shows the edit mode page title', () => {
          expect(findEditModeTitle().text()).toBe('Edit your dashboard');
        });

        it('does not show the dashboard title header', () => {
          expect(findDashboardTitle().exists()).toBe(false);
        });

        it('shows the Save button', () => {
          expect(findSaveButton().props('loading')).toBe(false);
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
          expect(findTitleInput().attributes()).toMatchObject({
            value: 'Analytics Overview',
            required: '',
          });
        });

        it('saves the dashboard changes when the "save" button is clicked', async () => {
          await findTitleInput().vm.$emit('input', 'New Title');

          await findSaveButton().vm.$emit('click');

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

        it('shows the "cancel" button', () => {
          expect(findCancelButton().exists()).toBe(true);
        });

        describe('and the "cancel" button is clicked', () => {
          beforeEach(() => {
            findCancelButton().vm.$emit('click');
          });

          it('disables the edit state', () => {
            expect(findEditModeTitle().exists()).toBe(false);
          });

          it('sets the grid to static mode', () => {
            expect(mockGridSetStatic).toHaveBeenCalledWith(true);
          });
        });

        it('does not show the "edit" button', () => {
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

  describe('when a dashboard is new and the editing feature flag is enabled', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();

      createWrapper(
        {
          isNewDashboard: true,
        },
        NEW_DASHBOARD(),
        { glFeatures: { combinedAnalyticsDashboardsEditor: true } },
      );
    });

    it('routes to the dashboard listing page when "cancel" is clicked', async () => {
      await findCancelButton().vm.$emit('click');

      expect($router.push).toHaveBeenCalledWith('/');
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

    it('shows the new dashboard page title', () => {
      expect(findEditModeTitle().text()).toBe('Create your dashboard');
    });

    it('shows the empty state', () => {
      expect(findEmptyState().props()).toMatchObject({
        svgPath: TEST_EMPTY_DASHBOARD_SVG_PATH,
        title: 'Add a visualization',
        description: 'Select a visualization from the sidebar to get started.',
      });
    });

    it('does not display the grid', () => {
      expect(findGrid().isVisible()).toBe(false);
    });

    it('hides the empty state and shows the grid when a visualization has been added', async () => {
      await findVisualizationSelector().vm.$emit('select', TEST_VISUALIZATION());

      expect(findEmptyState().exists()).toBe(false);

      expect(findGrid().isVisible()).toBe(true);
    });

    it('does not show the filters', () => {
      expect(findDateRangeFilter().exists()).toBe(false);
    });

    describe('when saving', () => {
      describe('and there is no title nor visualizations', () => {
        beforeEach(() => {
          findTitleInput().element.focus = jest.fn();

          return findSaveButton().vm.$emit('click');
        });

        it('does not save the dashboard', () => {
          expect(wrapper.emitted('save')).toBeUndefined();
        });

        it('shows the invalid state on the title input', () => {
          expect(findTitleFormGroup().attributes('state')).toBe(undefined);
          expect(findTitleFormGroup().attributes('invalid-feedback')).toBe(
            'This field is required.',
          );

          expect(findTitleInput().attributes('state')).toBe(undefined);
        });

        it('sets focus on the dashboard title input', () => {
          expect(findTitleInput().element.focus).toHaveBeenCalled();
        });

        describe('and a user then inputs a title', () => {
          beforeEach(() => {
            return findTitleInput().vm.$emit('input', 'New Title');
          });

          it('shows title input as valid', () => {
            expect(findTitleFormGroup().attributes('state')).toBe('true');
            expect(findTitleInput().attributes('state')).toBe('true');
          });
        });
      });

      describe('and there is a title but no visualizations', () => {
        beforeEach(async () => {
          await findTitleInput().vm.$emit('input', 'New Title');

          await findSaveButton().vm.$emit('click');
        });

        it('does not save the dashboard', () => {
          expect(wrapper.emitted('save')).toBeUndefined();
        });

        it('shows an alert', () => {
          expect(createAlert).toHaveBeenCalledWith({ message: 'Add a visualization' });
        });

        describe('and the component is destroyed', () => {
          beforeEach(() => {
            wrapper.destroy();

            return nextTick();
          });

          it('dismisses the alert', () => {
            expect(mockAlertDismiss).toHaveBeenCalled();
          });
        });

        describe('and saved is clicked after a visualization has been added', () => {
          beforeEach(async () => {
            await findVisualizationSelector().vm.$emit('select', TEST_VISUALIZATION());

            await findSaveButton().vm.$emit('click');
          });

          it('dismisses the alert', () => {
            expect(mockAlertDismiss).toHaveBeenCalled();
          });
        });
      });

      describe('and there is a title and visualizations', () => {
        beforeEach(async () => {
          await findTitleInput().vm.$emit('input', 'New Title');

          await findVisualizationSelector().vm.$emit('select', TEST_VISUALIZATION());

          await findSaveButton().vm.$emit('click');
        });

        it('shows title input as valid', () => {
          expect(findTitleFormGroup().attributes('state')).toBe('true');
          expect(findTitleInput().attributes('state')).toBe('true');
        });

        it('does not show an alert', () => {
          expect(mockAlertDismiss).not.toHaveBeenCalled();
        });

        it('saves the dashboard with a new a slug', () => {
          expect(wrapper.emitted('save')).toStrictEqual([
            [
              'new_title',
              {
                slug: 'new_title',
                title: 'New Title',
                panels: [expect.any(Object)],
                userDefined: true,
              },
            ],
          ]);
        });
      });
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

  describe('changes saved', () => {
    it.each`
      editing  | changesSaved | newState
      ${true}  | ${true}      | ${false}
      ${true}  | ${false}     | ${true}
      ${false} | ${true}      | ${false}
      ${false} | ${false}     | ${false}
    `(
      'when editing="$editing" and changesSaved="$changesSaved" the new editing state is "$newState',
      async ({ editing, changesSaved, newState }) => {
        createWrapper({ changesSaved, isNewDashboard: editing }, dashboard, {
          glFeatures: { combinedAnalyticsDashboardsEditor: true },
        });

        await nextTick();

        expect(findEditModeTitle().exists()).toBe(newState);
      },
    );
  });
});
