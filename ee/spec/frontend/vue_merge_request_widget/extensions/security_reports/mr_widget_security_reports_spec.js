import MrSecurityWidget from 'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';

describe('MR Widget Security Reports', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(MrSecurityWidget, {
      propsData: {
        mr: {},
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should mount the widget component', () => {
    expect(wrapper.findComponent(Widget).props()).toMatchObject({
      errorText: 'Security reports failed loading results',
      loadingText: 'Security scanning is loading',
      fetchCollapsedData: wrapper.vm.fetchCollapsedData,
      //   fetchExpandedData: wrapper.vm.fetchExpandedData,
      multiPolling: true,
    });
  });

  it('fetchCollapsedData - returns list of endpoints to be fetched', () => {
    expect(wrapper.vm.fetchCollapsedData().length).toBe(6);
  });
});
