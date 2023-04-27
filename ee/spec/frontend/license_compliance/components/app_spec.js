import { GlEmptyState, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import LicenseComplianceApp from 'ee/license_compliance/components/app.vue';
import DetectedLicensesTable from 'ee/license_compliance/components/detected_licenses_table.vue';
import PipelineInfo from 'ee/license_compliance/components/pipeline_info.vue';
import { REPORT_STATUS } from 'ee/license_compliance/store/modules/list/constants';

import * as getters from 'ee/license_compliance/store/modules/list/getters';

import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';
import { allowedLicense, deniedLicense } from 'ee_jest/vue_shared/license_compliance/mock_data';
import { stubTransition } from 'helpers/stub_transition';
import { TEST_HOST } from 'helpers/test_constants';

Vue.use(Vuex);

let wrapper;

const readLicensePoliciesEndpoint = `${TEST_HOST}/license_management`;
const managedLicenses = [allowedLicense, deniedLicense];
const licenses = [{}, {}];
const emptyStateSvgPath = '/';
const documentationPath = '/';

const noop = () => {};

const createComponent = ({ state, props, options }) => {
  const fakeStore = new Vuex.Store({
    modules: {
      licenseManagement: {
        namespaced: true,
        state: {
          managedLicenses,
        },
        getters: {
          isAddingNewLicense: () => false,
          hasPendingLicenses: () => false,
          isLicenseBeingUpdated: () => () => false,
        },
        actions: {
          fetchManagedLicenses: noop,
          setLicenseApproval: noop,
        },
      },
      licenseList: {
        namespaced: true,
        state: {
          licenses,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
          },
          ...state,
        },
        actions: {
          fetchLicenses: noop,
        },
        getters,
      },
    },
  });

  const mountFunc = options && options.mount ? mount : shallowMount;

  wrapper = mountFunc(LicenseComplianceApp, {
    propsData: {
      readLicensePoliciesEndpoint,
      ...props,
    },
    ...options,
    store: fakeStore,
    stubs: { transition: stubTransition() },
    provide: {
      emptyStateSvgPath,
      documentationPath,
    },
  });
};

describe('Project Licenses', () => {
  describe('when loading', () => {
    beforeEach(() => {
      createComponent({
        state: { initialized: false },
      });
    });

    it('shows the loading component', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not show the empty state component', () => {
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(false);
    });

    it('does not show the list of detected in project licenses', () => {
      expect(wrapper.findComponent(DetectedLicensesTable).exists()).toBe(false);
    });

    it('does not show the list of license policies', () => {
      expect(wrapper.findComponent(LicenseManagement).exists()).toBe(false);
    });
  });

  describe('when empty state', () => {
    beforeEach(() => {
      createComponent({
        state: {
          initialized: true,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
            status: REPORT_STATUS.jobNotSetUp,
          },
        },
      });
    });

    it('shows the empty state component', () => {
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('does not show the loading component', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    });

    it('does not show the list of detected in project licenses', () => {
      expect(wrapper.findComponent(DetectedLicensesTable).exists()).toBe(false);
    });
  });

  describe('when page is shown', () => {
    beforeEach(() => {
      createComponent({
        state: {
          initialized: true,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
            status: REPORT_STATUS.ok,
          },
        },
      });
    });

    it('does not render a policy violations alert', () => {
      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
    });

    it('renders the "Detected in project" table', () => {
      expect(wrapper.findComponent(DetectedLicensesTable).exists()).toBe(true);
    });

    it('renders the pipeline info', () => {
      expect(wrapper.findComponent(PipelineInfo).exists()).toBe(true);
    });
  });
});
