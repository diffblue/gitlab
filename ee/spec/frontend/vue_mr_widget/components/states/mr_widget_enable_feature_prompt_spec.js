import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MrWidgetEnableFeaturePrompt from 'ee/vue_merge_request_widget/components/states/mr_widget_enable_feature_prompt.vue';
import { stubExperiments } from 'helpers/experimentation_helper';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

const FEATURE = 'my_feature_name';
const LOCAL_STORAGE_KEY = `MrWidgetEnableFeaturePrompt.${FEATURE}.dismissed`;

describe('MrWidgetEnableFeaturePrompt', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(MrWidgetEnableFeaturePrompt, {
      propsData: { feature: FEATURE },
      slots: {
        default: 'this is my content',
      },
    });
  };

  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findDismissButton = () => wrapper.find('[data-track-action="dismissed"]');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the experiment is not enabled', () => {
    it('renders nothing', () => {
      stubExperiments({ [FEATURE]: 'control' });
      expect(wrapper.text()).toBe('');
    });
  });

  describe('when the experiment is enabled', () => {
    beforeAll(() => {
      stubExperiments({ [FEATURE]: 'candidate' });
      localStorage.removeItem(LOCAL_STORAGE_KEY);
    });

    it('shows a neutral icon', () => {
      expect(findCiIcon().props('status').group).toBe('notification');
      expect(findCiIcon().props('status').icon).toBe('status-neutral');
      expect(findCiIcon().props('size')).toBe(24);
    });

    it('renders the provided slots', () => {
      expect(wrapper.text()).toBe('this is my content');
    });

    it('can be dismissed', async () => {
      const button = findDismissButton();
      button.vm.$emit('click');

      await nextTick();

      expect(localStorage.getItem(LOCAL_STORAGE_KEY)).toBe('true');
      expect(wrapper.text()).toBe('');
    });
  });
});
