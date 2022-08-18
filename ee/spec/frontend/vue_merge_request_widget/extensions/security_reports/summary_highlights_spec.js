import { GlSprintf } from '@gitlab/ui';
import SummaryHighlights from 'ee/vue_merge_request_widget/extensions/security_reports/summary_highlights.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('MR Widget Security Reports - Summary Highlights', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(SummaryHighlights, {
      propsData: {
        highlights: {
          critical: 10,
          high: 20,
          other: 60,
        },
      },
      stubs: { GlSprintf },
    });
  };

  it('should display the summary highlights properly', () => {
    createComponent();

    expect(wrapper.html()).toMatchSnapshot();
  });
});
