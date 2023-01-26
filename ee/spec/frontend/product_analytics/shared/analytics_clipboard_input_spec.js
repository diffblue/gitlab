import { nextTick } from 'vue';
import { GlButton, GlFormGroup, GlFormInput, GlTooltip, GlFormInputGroup } from '@gitlab/ui';
import AnalyticsClipboardInput, {
  TOOLTIP_ALERT_TIMEOUT,
} from 'ee/product_analytics/shared/analytics_clipboard_input.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

const { i18n } = AnalyticsClipboardInput;

const TEST_LABEL = 'SDK key';
const TEST_DESCRIPTION = 'The SDK key';
const TEST_VALUE = 'XyZ';

describe('AnalyticsClipboardInput', () => {
  let wrapper;

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findButton = () => wrapper.findComponent(GlButton);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findTooltip = () => wrapper.findComponent(GlTooltip);

  const createWrapper = () => {
    wrapper = shallowMountExtended(AnalyticsClipboardInput, {
      propsData: {
        label: TEST_LABEL,
        description: TEST_DESCRIPTION,
        value: TEST_VALUE,
      },
      stubs: {
        'gl-form-group': GlFormGroup,
        'gl-form-input-group': GlFormInputGroup,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('renders label and description', () => {
    expect(findFormGroup().attributes('label')).toBe(TEST_LABEL);
    expect(findFormGroup().props('labelDescription')).toBe(TEST_DESCRIPTION);
    expect(findInput().attributes('value')).toBe(TEST_VALUE);
  });

  it('copies provided value to clipboard and updates the tooltip', async () => {
    jest.spyOn(navigator.clipboard, 'writeText');

    findButton().vm.$emit('click');

    await waitForPromises();

    expect(navigator.clipboard.writeText).toHaveBeenCalledWith(TEST_VALUE);
    expect(findTooltip().attributes('title')).toBe(i18n.copied);

    jest.advanceTimersByTime(TOOLTIP_ALERT_TIMEOUT);

    await nextTick();

    expect(findTooltip().attributes('title')).toBe(i18n.copyToClipboard);
  });

  it('shows hint when copying fails', async () => {
    jest.spyOn(navigator.clipboard, 'writeText').mockRejectedValue(new Error('Failed'));

    expect(findFormGroup().attributes('description')).toBe('');

    findButton().vm.$emit('click');

    await waitForPromises();

    expect(findFormGroup().attributes('description')).toBe(i18n.failedToCopy);
    expect(findTooltip().attributes('title')).toBe(i18n.copyToClipboard);
  });
});
