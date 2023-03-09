import { GlAlert, GlEmptyState, GlFormCheckbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import SecurityDashboardTable from 'ee/security_dashboard/components/pipeline/security_dashboard_table.vue';
import SecurityDashboardTableRow from 'ee/security_dashboard/components/pipeline/security_dashboard_table_row.vue';
import { setupStore } from 'ee/security_dashboard/store';
import {
  RECEIVE_VULNERABILITIES_ERROR,
  RECEIVE_VULNERABILITIES_SUCCESS,
  REQUEST_VULNERABILITIES,
} from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import mockDataVulnerabilities from '../../store/modules/vulnerabilities/data/mock_data_vulnerabilities';

Vue.use(Vuex);

describe('Security Dashboard Table', () => {
  const vulnerabilitiesEndpoint = '/vulnerabilitiesEndpoint.json';
  let store;
  let wrapper;

  beforeEach(() => {
    store = new Vuex.Store();
    setupStore(store);
    wrapper = shallowMountExtended(SecurityDashboardTable, {
      store,
    });
    store.state.vulnerabilities.vulnerabilitiesEndpoint = vulnerabilitiesEndpoint;
  });

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findSelectionSummaryCollapse = () => wrapper.findByTestId('selection-summary-collapse');

  describe('while loading', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${REQUEST_VULNERABILITIES}`);
    });

    it('should render 10 skeleton rows in the table', () => {
      expect(wrapper.findAllComponents(SecurityDashboardTableRow)).toHaveLength(10);
    });
  });

  describe('with a list of vulnerabilities', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, {
        vulnerabilities: mockDataVulnerabilities,
        pageInfo: {},
      });
    });

    it('should render a row for each vulnerability', () => {
      expect(wrapper.findAllComponents(SecurityDashboardTableRow)).toHaveLength(
        mockDataVulnerabilities.length,
      );
    });

    it('should not show the multi select box', () => {
      expect(findSelectionSummaryCollapse().attributes('visible')).toBeUndefined();
    });

    it('should show the select all as unchecked', () => {
      expect(findCheckbox().attributes('checked')).toBeUndefined();
    });

    describe('with vulnerabilities selected', () => {
      beforeEach(() => {
        findCheckbox().vm.$emit('change');
      });

      it('should show the multi select box', () => {
        expect(findSelectionSummaryCollapse().attributes('visible')).toBe('true');
      });

      it('should show the select all as checked', () => {
        expect(findCheckbox().attributes('checked')).toBe('true');
      });
    });
  });

  describe('with no vulnerabilities', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, {
        vulnerabilities: [],
        pageInfo: {},
      });
    });

    it('should render the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_ERROR}`);
    });

    it('should not render the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('should render the error alert', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('with a custom empty state', () => {
    beforeEach(() => {
      wrapper = shallowMount(SecurityDashboardTable, {
        store,
        slots: {
          'empty-state': '<div class="customEmptyState">Hello World</div>',
        },
      });

      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, {
        vulnerabilities: [],
        pageInfo: {},
      });
    });

    it('should render the custom empty state', () => {
      expect(wrapper.find('.customEmptyState').exists()).toBe(true);
    });
  });
});
