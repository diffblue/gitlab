import { shallowMount } from '@vue/test-utils';
import MetricReportsIssueBody from 'ee/vue_shared/metrics_reports/components/metrics_reports_issue_body.vue';

describe('Metrics reports issue body', () => {
  let wrapper;

  describe('when metric did not change', () => {
    it('should render metric with no changes text', () => {
      wrapper = shallowMount(MetricReportsIssueBody, {
        propsData: {
          issue: {
            name: 'name',
            value: 'value',
          },
        },
      });

      const metric = wrapper.element.querySelector('.js-metrics-reports-issue-text');

      expect(metric.innerText.trim()).toEqual('name: value (No changes)');
    });
  });

  describe('when metric changed', () => {
    it('should render metric with change', () => {
      wrapper = shallowMount(MetricReportsIssueBody, {
        propsData: {
          issue: {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
        },
      });

      const metric = wrapper.element.querySelector('.js-metrics-reports-issue-text');

      expect(metric.innerText.trim()).toEqual('name: value (prev)');
    });
  });

  describe('when metric is new', () => {
    it('should render metric with new badge', () => {
      wrapper = shallowMount(MetricReportsIssueBody, {
        propsData: {
          issue: {
            name: 'name',
            value: 'value',
            isNew: true,
          },
        },
      });

      const metric = wrapper.element.querySelector('.js-metrics-reports-issue-text');
      const badge = wrapper.element.querySelector('.js-metrics-reports-issue-badge');

      expect(metric.innerText.trim()).toEqual('name: value');
      expect(badge.innerText.trim()).toEqual('New');
    });
  });

  describe('when metric was removed', () => {
    it('should render metric with removed badge', () => {
      wrapper = shallowMount(MetricReportsIssueBody, {
        propsData: {
          issue: {
            name: 'name',
            value: 'value',
            wasRemoved: true,
          },
        },
      });

      const metric = wrapper.element.querySelector('.js-metrics-reports-issue-text');
      const badge = wrapper.element.querySelector('.js-metrics-reports-issue-badge');

      expect(metric.innerText.trim()).toEqual('name: value');
      expect(badge.innerText.trim()).toEqual('Removed');
    });
  });
});
