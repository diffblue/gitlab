import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FalsePositiveAlert from 'ee/vulnerabilities/components/false_positive_alert.vue';

const TITLE = 'False positive detected';
const MESSAGE =
  'The scanner determined this vulnerability to be a false positive. Verify the evaluation before changing its status. %{linkStart}Learn more about false positive detection.%{linkEnd}';

describe('False positive alert component', () => {
  let wrapper;

  const createWrapper = (provide) => {
    return shallowMount(FalsePositiveAlert, {
      provide: {
        canViewFalsePositive: true,
        ...provide,
      },
    });
  };

  it('should render the alert message', () => {
    wrapper = createWrapper();

    const { i18n } = wrapper.vm.$options;

    expect(i18n.title).toEqual(TITLE);
    expect(i18n.message).toEqual(MESSAGE);

    expect(wrapper.element).toMatchSnapshot();
  });

  it('should not render the alert message when canViewFalsePositive is false', () => {
    wrapper = createWrapper({ canViewFalsePositive: false });

    expect(wrapper.findComponent(GlAlert).exists()).toEqual(false);
  });
});
