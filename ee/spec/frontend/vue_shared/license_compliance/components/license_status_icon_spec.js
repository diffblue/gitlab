import { shallowMount } from '@vue/test-utils';
import ReportItem from 'ee/vue_shared/license_compliance/components/license_status_icon.vue';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/ci/reports/constants';

describe('LicenseStatusIcon', () => {
  let wrapper;

  const createComponent = ({ status }) => {
    wrapper = shallowMount(ReportItem, {
      propsData: {
        status,
      },
    });
  };

  it.each([STATUS_SUCCESS, STATUS_NEUTRAL, STATUS_FAILED])(
    'renders "%s" state correctly',
    (status) => {
      createComponent({ status });

      expect(wrapper.element).toMatchSnapshot();
    },
  );
});
