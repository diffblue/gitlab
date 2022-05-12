import { mount } from '@vue/test-utils';
import component from 'ee/vue_merge_request_widget/components/status_check_issue_body.vue';
import SummaryRow from '~/reports/components/summary_row.vue';
import { approvedChecks } from 'ee_jest/reports/status_checks_report/mock_data';

describe('status check issue body', () => {
  let wrapper;

  const findSummaryRow = () => wrapper.findComponent(SummaryRow);

  const [defaultStatusCheck] = approvedChecks;

  const createComponent = (statusCheck = {}) => {
    wrapper = mount(component, {
      propsData: {
        issue: {
          ...defaultStatusCheck,
          ...statusCheck,
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the status check name and external URL', () => {
    expect(wrapper.text()).toBe(`${defaultStatusCheck.name}: ${defaultStatusCheck.external_url}`);
  });

  it.each`
    status       | icon
    ${'passed'}  | ${'success'}
    ${'pending'} | ${'pending'}
    ${'failed'}  | ${'failed'}
  `('sets the status-icon to $icon when the check status is $status', ({ status, icon }) => {
    createComponent({ status });

    expect(findSummaryRow().props('statusIcon')).toBe(icon);
  });
});
