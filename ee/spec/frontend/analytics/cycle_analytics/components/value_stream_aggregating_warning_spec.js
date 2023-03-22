import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import ValueStreamAggregatingWarning from 'ee/analytics/cycle_analytics/components/value_stream_aggregating_warning.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const valueStreamTitle = 'New value stream';
const aggregatingMessage = `'${valueStreamTitle}' is collecting the data. This can take a few minutes.`;
const nextUpdateMsg =
  'If you have recently upgraded your GitLab license from a tier without this feature, it can take up to 30 minutes for data to collect and display.';
const secondaryBtnLink = '/help/user/group/value_stream_analytics/index#create-a-value-stream';

const createComponent = (props = {}) =>
  extendedWrapper(
    shallowMount(ValueStreamAggregatingWarning, {
      propsData: {
        valueStreamTitle,
        ...props,
      },
    }),
  );

describe('ValueStreamAggregatingWarning', () => {
  let wrapper = null;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findPrimaryButtonTxt = () => findAlert().attributes('primarybuttontext');
  const findSecondaryButtonTxt = () => findAlert().attributes('secondarybuttontext');
  const findSecondaryButtonLink = () => findAlert().attributes('secondarybuttonlink');

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the primary button', () => {
      expect(findPrimaryButtonTxt()).toBe('Reload page');
    });

    it('renders the secondary button with a docs link', () => {
      expect(findSecondaryButtonTxt()).toBe('Learn more');
      expect(findSecondaryButtonLink()).toBe(secondaryBtnLink);
    });

    it('renders the aggregating warning and estimated next update', () => {
      const content = findAlert().text();
      expect(content).toContain(aggregatingMessage);
      expect(content).toContain(nextUpdateMsg);
    });

    it('emits the `reload` action when the primary button is clicked', () => {
      expect(wrapper.emitted('reload')).toBeUndefined();

      findAlert().vm.$emit('primaryAction');

      expect(wrapper.emitted('reload')).toHaveLength(1);
    });
  });
});
