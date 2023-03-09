import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import MetricsReportsIssueBody from 'ee/vue_shared/metrics_reports/components/metrics_reports_issue_body.vue';
import GroupedMetricsReportsApp from 'ee/vue_shared/metrics_reports/grouped_metrics_reports_app.vue';
import { getStoreConfig } from 'ee/vue_shared/metrics_reports/store';
import Api from '~/api';

jest.mock('~/api.js');

Vue.use(Vuex);

describe('Grouped metrics reports app', () => {
  let wrapper;
  let mockStore;

  const findExpandButton = () => wrapper.find('[data-testid="report-section-expand-button"]');

  const mountComponent = (glFeatures = {}) => {
    wrapper = mount(GroupedMetricsReportsApp, {
      store: mockStore,
      propsData: {
        endpoint: 'metrics.json',
      },
      provide: {
        glFeatures,
      },
    });
  };

  beforeEach(() => {
    const { actions, ...storeConfig } = getStoreConfig();
    mockStore = new Vuex.Store({
      ...storeConfig,
      actions: { ...actions, fetchMetrics: () => ({}) },
    });
    mountComponent();
  });

  describe('while loading', () => {
    beforeEach(() => {
      mockStore.state.isLoading = true;
      mountComponent();
    });

    it('renders loading state', () => {
      const header = wrapper.element.querySelector('.js-code-text');

      expect(header.innerText.trim()).toEqual('Metrics reports are loading');
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      mockStore.state.isLoading = false;
      mockStore.state.hasError = true;
      mountComponent();
    });

    it('renders error state', () => {
      const header = wrapper.element.querySelector('.js-code-text');

      expect(header.innerText.trim()).toEqual('Metrics reports failed loading results');
    });
  });

  describe('with metrics', () => {
    describe('when user expands to view metrics', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 0;
        mockStore.state.unchangedMetrics = [
          {
            name: 'name',
            value: 'value',
          },
        ];
      });

      it('tracks group_code_coverage_visit_total metric', () => {
        findExpandButton().trigger('click');

        expect(Api.trackRedisHllUserEvent).toHaveBeenCalledTimes(1);
        expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(wrapper.vm.$options.expandEvent);
      });
    });

    describe('with no changes', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 0;
        mockStore.state.unchangedMetrics = [
          {
            name: 'name',
            value: 'value',
          },
        ];
        mountComponent();
      });

      it('renders no changes header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports did not change');
      });
    });

    describe('with one change', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 1;
        mockStore.state.changedMetrics = [
          {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
        ];
        mountComponent();
      });

      it('renders one change header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports changed on 1 point');
      });
    });

    describe('with multiple changes', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 2;
        mockStore.state.changedMetrics = [
          {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
          {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
        ];
        mountComponent();
      });

      it('renders multiple changes header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports changed on 2 points');
      });
    });

    describe('with new metrics', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 1;
        mockStore.state.newMetrics = [
          {
            name: 'name',
            value: 'value',
          },
        ];
        mountComponent();
      });

      it('renders new changes header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports changed on 1 point');
      });
    });

    describe('with removed metrics', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 1;
        mockStore.state.removedMetrics = [
          {
            name: 'name',
            value: 'value',
          },
        ];
        mountComponent();
      });

      it('renders new changes header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports changed on 1 point');
      });
    });

    describe('when has metrics', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 1;
        mockStore.state.changedMetrics = [
          {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
        ];
        mountComponent();
      });

      it('renders custom metric issue body', () => {
        const issueBody = wrapper.findComponent(MetricsReportsIssueBody);

        expect(issueBody.props('issue').name).toEqual('name');
        expect(issueBody.props('issue').value).toEqual('value');
        expect(issueBody.props('issue').previous_value).toEqual('prev');
      });
    });
  });
});
