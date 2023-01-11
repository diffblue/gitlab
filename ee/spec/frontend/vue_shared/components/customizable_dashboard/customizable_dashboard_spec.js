import { GridStack } from 'gridstack';
import * as Sentry from '@sentry/browser';
import { RouterLinkStub } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import WidgetsBase from 'ee/vue_shared/components/customizable_dashboard/widgets_base.vue';
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

  const findGridStackWidgets = () => wrapper.findAllByTestId('grid-stack-widget');
  const findWidgets = () => wrapper.findAllComponents(WidgetsBase);
  const findEditButton = () => wrapper.findByTestId('dashboard-edit-btn');
  const findCancelEditButton = () => wrapper.findByTestId('dashboard-cancel-edit-btn');
  const findCodeButton = () => wrapper.findByTestId('dashboard-code-btn');

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
      dashboard.widgets.map((widget, index) => [
        widget.id,
        widget.title,
        widget.visualization,
        widget.gridAttributes,
        widget.queryOverrides,
        index,
      ]),
    )(
      'should render the widget for %s',
      (id, title, visualization, gridAttributes, queryOverrides, index) => {
        expect(findWidgets().at(index).props()).toMatchObject({
          title,
          visualization,
          queryOverrides,
        });

        expect(findGridStackWidgets().at(index).attributes()).toMatchObject({
          'gs-id': `${id}`,
          'gs-h': `${gridAttributes.height}`,
          'gs-w': `${gridAttributes.width}`,
        });
      },
    );

    it('calls createAlert when a widget emits an error', () => {
      const error = new Error('foo');

      findWidgets().at(0).vm.$emit('error', error);

      expect(createAlert).toHaveBeenCalledWith({
        message: `An error occured while loading the ${dashboard.widgets[0].title} widget.`,
        captureError: true,
        error,
      });
    });

    it('shows Edit Button', () => {
      expect(findEditButton().exists()).toBe(true);
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

    it('updates widgets when their values change', async () => {
      await wrapper.vm.updateWidgetWithGridStackItem({ id: 1, x: 10, y: 20, w: 30, h: 40 });

      expect(findGridStackWidgets().at(0).attributes()).toMatchObject({
        id: 'widget-1',
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
});
