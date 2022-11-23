import { nextTick } from 'vue';
import { GlSprintf } from '@gitlab/ui';
import SummaryText from 'ee/vue_merge_request_widget/extensions/security_reports/summary_text.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('MR Widget Security Reports - Summary Text', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(SummaryText, {
      propsData: {
        totalNewVulnerabilities: 0,
        ...propsData,
      },
      stubs: { GlSprintf },
    });
  };

  it('should display a loading text when is-loading is true', async () => {
    createComponent({ propsData: { isLoading: true } });
    await nextTick();
    expect(wrapper.findByText('Security scanning is loading').exists()).toBe(true);
  });

  it('should display a meaningful text when there are no new vulnerabilities', async () => {
    createComponent();
    await nextTick();
    expect(wrapper.html()).toBe(
      '<div>Security scanning detected no new potential vulnerabilities</div>',
    );
  });

  it('should display a meaningful text when there are new vulnerabilities', async () => {
    createComponent({ propsData: { totalNewVulnerabilities: 5 } });
    await nextTick();
    expect(wrapper.html()).toBe(
      '<div>Security scanning detected <strong>5</strong> new potential vulnerabilities</div>',
    );
  });

  it('should display an error message when error property is true', () => {
    createComponent({ propsData: { error: true, scanner: 'Container Scanning' } });
    expect(wrapper.findByText('Container Scanning: Loading resulted in an error').exists()).toBe(
      true,
    );
  });
});
