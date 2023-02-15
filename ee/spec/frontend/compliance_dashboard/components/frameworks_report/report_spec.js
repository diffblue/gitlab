import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ComplianceFrameworksReport from 'ee/compliance_dashboard/components/frameworks_report/report.vue';

Vue.use(VueApollo);

describe('ComplianceFrameworksReport component', () => {
  let wrapper;

  const createComponent = (mountFn = shallowMount, props = {}) => {
    return extendedWrapper(
      mountFn(ComplianceFrameworksReport, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default behavior', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders', () => {
      expect(wrapper.find('#compliance-framework-report').exists()).toBe(true);
    });
  });
});
