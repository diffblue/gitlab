import { shallowMount } from '@vue/test-utils';
import Weight from 'ee/sidebar/components/weight/weight.vue';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';
import { ENTER_KEY_CODE } from '~/lib/utils/keycodes';
import eventHub from '~/sidebar/event_hub';

describe('Weight', () => {
  let wrapper;

  const defaultProps = {
    weightNoneValue: 'None',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(Weight, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const containsCollapsedLoadingIcon = () =>
    wrapper.find('.js-weight-collapsed-loading-icon').exists();
  const containsLoadingIcon = () => wrapper.find('.js-weight-loading-icon').exists();
  const findCollapsedLabel = () => wrapper.find('.js-weight-collapsed-weight-label');
  const findLabelValue = () => wrapper.find('.js-weight-weight-label-value');
  const findLabelNoValue = () => wrapper.find('.js-weight-weight-label .no-value');
  const findCollapsedBlock = () => wrapper.find('.js-weight-collapsed-block');
  const findEditLink = () => wrapper.find('.js-weight-edit-link');
  const findRemoveLink = () => wrapper.find('.js-weight-remove-link');
  const containsEditableField = () => wrapper.find({ ref: 'editableField' }).exists();
  const containsInputError = () => wrapper.find('.gl-field-error').exists();

  it('shows loading spinner when fetching', () => {
    createComponent({
      fetching: true,
    });

    expect(containsCollapsedLoadingIcon()).toBe(true);
    expect(containsLoadingIcon()).toBe(true);
  });

  it('shows loading spinner when loading', () => {
    createComponent({
      fetching: false,
      loading: true,
    });

    // We show the value in the collapsed view instead of the loading icon
    expect(containsCollapsedLoadingIcon()).toBe(false);
    expect(containsLoadingIcon()).toBe(true);
  });

  it('shows weight value', () => {
    const expectedWeight = 3;

    createComponent({
      fetching: false,
      weight: expectedWeight,
    });

    expect(findCollapsedLabel().text()).toBe(`${expectedWeight}`);
    expect(findLabelValue().text()).toBe(`${expectedWeight}`);
  });

  it('shows weight no-value', () => {
    const expectedWeight = null;

    createComponent({
      fetching: false,
      weight: expectedWeight,
    });

    expect(findCollapsedLabel().text()).toBe(defaultProps.weightNoneValue);
    expect(findLabelNoValue().text()).toBe(defaultProps.weightNoneValue);
  });

  it('adds `collapse-after-update` class when clicking the collapsed block', async () => {
    createComponent();

    findCollapsedBlock().trigger('click');

    await wrapper.vm.$nextTick;

    expect(wrapper.classes()).toContain('collapse-after-update');
  });

  it('shows dropdown on "Edit" link click', async () => {
    createComponent({
      editable: true,
    });

    expect(containsEditableField()).toBe(false);

    findEditLink().trigger('click');

    await wrapper.vm.$nextTick;

    expect(containsEditableField()).toBe(true);
  });

  it('emits event on input submission', async () => {
    const mockId = 123;
    const expectedWeightValue = '3';

    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    createComponent({
      editable: true,
      id: mockId,
    });

    findEditLink().trigger('click');

    await wrapper.vm.$nextTick;

    const event = new CustomEvent('keydown');
    event.keyCode = ENTER_KEY_CODE;

    const { editableField } = wrapper.vm.$refs;
    editableField.click();
    editableField.value = expectedWeightValue;
    editableField.dispatchEvent(event);

    await wrapper.vm.$nextTick;

    expect(containsInputError()).toBe(false);
    expect(eventHub.$emit).toHaveBeenCalledWith('updateWeight', {
      id: mockId,
      value: expectedWeightValue,
    });
  });

  it('emits event on remove weight link click', async () => {
    const mockId = 234;

    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    createComponent({
      editable: true,
      weight: 3,
      id: mockId,
    });

    findRemoveLink().trigger('click');

    await wrapper.vm.$nextTick;

    expect(containsInputError()).toBe(false);
    expect(eventHub.$emit).toHaveBeenCalledWith('updateWeight', { id: mockId, value: '' });
  });

  it('triggers error on invalid negative integer value', async () => {
    createComponent({
      editable: true,
    });

    findEditLink().trigger('click');

    await wrapper.vm.$nextTick;

    const event = new CustomEvent('keydown');
    event.keyCode = ENTER_KEY_CODE;

    const { editableField } = wrapper.vm.$refs;
    editableField.click();
    editableField.value = -9001;
    editableField.dispatchEvent(event);

    await wrapper.vm.$nextTick;

    expect(containsInputError()).toBe(true);
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(() => {
      createComponent({
        editable: true,
      });

      trackingSpy = mockTracking('_category_', wrapper.element, (obj, what) =>
        jest.spyOn(obj, what).mockImplementation(() => {}),
      );
    });

    afterEach(() => {
      unmockTracking();
    });

    it('calls trackEvent when "Edit" is clicked', async () => {
      triggerEvent(findEditLink().element);

      await wrapper.vm.$nextTick;

      expect(trackingSpy).toHaveBeenCalled();
    });
  });
});
