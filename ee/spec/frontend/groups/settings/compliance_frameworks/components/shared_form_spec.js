import { GlForm, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import SharedForm from 'ee/groups/settings/compliance_frameworks/components/shared_form.vue';
import * as Utils from 'ee/groups/settings/compliance_frameworks/utils';
import waitForPromises from 'helpers/wait_for_promises';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';
import { frameworkFoundResponse, suggestedLabelColors } from '../mock_data';
import { GlFormGroup, GlFormInput } from '../stubs';

describe('SharedForm', () => {
  let wrapper;
  const defaultPropsData = {
    submitButtonText: 'Save changes',
  };
  const defaultProvideData = {
    pipelineConfigurationFullPathEnabled: true,
    pipelineConfigurationEnabled: true,
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findNameGroup = () => wrapper.find('[data-testid="name-input-group"]');
  const findNameInput = () => wrapper.find('[data-testid="name-input"]');
  const findDescriptionGroup = () => wrapper.find('[data-testid="description-input-group"]');
  const findDescriptionInput = () => wrapper.find('[data-testid="description-input"]');
  const findPipelineConfigurationGroup = () =>
    wrapper.find('[data-testid="pipeline-configuration-input-group"]');
  const findPipelineConfigurationInput = () =>
    wrapper.find('[data-testid="pipeline-configuration-input"]');
  const findColorPicker = () => wrapper.findComponent(ColorPicker);
  const findSubmitBtn = () => wrapper.find('[data-testid="submit-btn"]');
  const findCancelBtn = () => wrapper.find('[data-testid="cancel-btn"]');
  const findDisabledPopover = () =>
    wrapper.find('[data-testid="disabled-pipeline-configuration-input-popover"]');
  const findDisabledPipelineConfigurationGroup = () =>
    wrapper.find('[data-testid="disabled-pipeline-configuration-input-group"]');

  function createComponent(props = {}, provide = {}) {
    return shallowMount(SharedForm, {
      propsData: {
        ...defaultPropsData,
        ...props,
      },
      provide: {
        ...defaultProvideData,
        ...provide,
      },
      stubs: {
        GlFormGroup,
        GlFormInput,
        GlSprintf,
      },
    });
  }

  beforeAll(() => {
    gon.suggested_label_colors = suggestedLabelColors;
  });

  describe('Fields', () => {
    it('shows the correct input and button fields', () => {
      wrapper = createComponent();

      expect(findNameInput().exists()).toBe(true);
      expect(findDescriptionInput().exists()).toBe(true);
      expect(findPipelineConfigurationInput().exists()).toBe(true);
      expect(findColorPicker().exists()).toBe(true);
      expect(findSubmitBtn().exists()).toBe(true);
      expect(findCancelBtn().exists()).toBe(true);
      expect(findDisabledPipelineConfigurationGroup().exists()).toBe(false);
    });

    it('sets the submit button text from the property', () => {
      wrapper = createComponent();

      expect(findSubmitBtn().text()).toBe(defaultPropsData.submitButtonText);
    });

    it.each([true, false])(
      'renders the pipeline configuration correctly when enabled is %s',
      (enabled) => {
        wrapper = createComponent({}, { pipelineConfigurationFullPathEnabled: enabled });

        expect(findPipelineConfigurationGroup().exists()).toBe(enabled);
      },
    );

    describe('When pipeline configuration is not enabled', () => {
      it('renders disabled pipeline configuration input', () => {
        wrapper = createComponent({}, { pipelineConfigurationEnabled: false });

        expect(findDisabledPopover().exists()).toBe(true);
      });
    });
  });

  describe('Validation', () => {
    it.each`
      name        | validity
      ${null}     | ${null}
      ${''}       | ${false}
      ${'foobar'} | ${true}
    `('sets the correct state to the name input and group', ({ name, validity }) => {
      wrapper = createComponent({ name });

      expect(findNameGroup().props('state')).toBe(validity);
      expect(findNameInput().props('state')).toBe(validity);
    });

    it.each`
      description | validity
      ${null}     | ${null}
      ${''}       | ${false}
      ${'foobar'} | ${true}
    `('sets the correct state to the description input and group', ({ description, validity }) => {
      wrapper = createComponent({ description });

      expect(findDescriptionGroup().props('state')).toBe(validity);
      expect(findDescriptionInput().props('state')).toBe(validity);
    });

    it.each`
      pipelineConfigurationFullPath | message
      ${'foobar'}                   | ${'Invalid format'}
      ${'foo.yml@bar/baz'}          | ${'Configuration not found'}
    `(
      'sets the correct invalid message to the group',
      async ({ pipelineConfigurationFullPath, message }) => {
        jest.spyOn(Utils, 'fetchPipelineConfigurationFileExists').mockReturnValue(false);

        wrapper = createComponent({ pipelineConfigurationFullPath });

        await waitForPromises();

        expect(findPipelineConfigurationGroup().attributes('invalid-feedback')).toBe(message);
      },
    );

    it.each`
      pipelineConfigurationFullPath | validity
      ${null}                       | ${null}
      ${''}                         | ${null}
      ${'foobar'}                   | ${false}
      ${'foo.yml@bar/zab'}          | ${false}
      ${'foo.yaml@bar/baz'}         | ${true}
      ${'foo.yml@bar/baz'}          | ${true}
    `(
      'sets the correct state for the input and group when pipeline configuration is $pipelineConfigurationFullPath',
      async ({ pipelineConfigurationFullPath, validity }) => {
        jest
          .spyOn(Utils, 'fetchPipelineConfigurationFileExists')
          .mockReturnValue(Boolean(validity));

        wrapper = createComponent({ pipelineConfigurationFullPath });

        await waitForPromises();

        expect(findPipelineConfigurationGroup().props('state')).toBe(validity);
        expect(findPipelineConfigurationInput().props('state')).toBe(validity);
      },
    );

    it.each`
      color        | validity
      ${null}      | ${null}
      ${''}        | ${null}
      ${'foobar'}  | ${false}
      ${'#00'}     | ${false}
      ${'#000'}    | ${true}
      ${'#000000'} | ${true}
    `('sets the correct state to the color picker', ({ color, validity }) => {
      wrapper = createComponent({ color });

      expect(findColorPicker().props('state')).toBe(validity);
    });

    it.each`
      name     | description | color     | pipelineConfigurationFullPath | disabled
      ${null}  | ${null}     | ${null}   | ${null}                       | ${'true'}
      ${'Foo'} | ${null}     | ${null}   | ${null}                       | ${'true'}
      ${null}  | ${'Bar'}    | ${null}   | ${null}                       | ${'true'}
      ${null}  | ${null}     | ${'#000'} | ${null}                       | ${'true'}
      ${null}  | ${null}     | ${null}   | ${'foo.yml@bar/zab'}          | ${'true'}
      ${'Foo'} | ${''}       | ${''}     | ${''}                         | ${'true'}
      ${'Foo'} | ${'Bar'}    | ${'#000'} | ${''}                         | ${undefined}
      ${'Foo'} | ${'Bar'}    | ${'#000'} | ${'foo.yml@bar/baz'}          | ${undefined}
    `(
      'should set the submit buttons disabled attribute to $disabled when name: $name, description: $description, color: $color, pipelineConfigurationFullPath: $pipelineConfigurationFullPath',
      async ({ name, description, color, pipelineConfigurationFullPath, disabled }) => {
        if (pipelineConfigurationFullPath?.includes('zab')) {
          jest.spyOn(Utils, 'fetchPipelineConfigurationFileExists').mockReturnValue(false);
        } else {
          jest.spyOn(Utils, 'fetchPipelineConfigurationFileExists').mockReturnValue(true);
        }

        wrapper = createComponent({ name, description, color, pipelineConfigurationFullPath });

        await waitForPromises();

        expect(findSubmitBtn().attributes('disabled')).toBe(disabled);
      },
    );
  });

  describe('Updating data', () => {
    it('updates the initial form data when the props are updated', async () => {
      const { name, description, pipelineConfigurationFullPath, color } = frameworkFoundResponse;
      wrapper = createComponent();

      expect(findNameInput().props('value')).toBe(null);
      expect(findDescriptionInput().props('value')).toBe(null);
      expect(findPipelineConfigurationInput().props('value')).toBe(null);
      expect(findColorPicker().props('value')).toBe(null);

      await wrapper.setProps({ name, description, pipelineConfigurationFullPath, color });

      expect(findNameInput().props('value')).toBe(name);
      expect(findDescriptionInput().props('value')).toBe(description);
      expect(findPipelineConfigurationInput().props('value')).toBe(pipelineConfigurationFullPath);
      expect(findColorPicker().props('value')).toBe(color);
    });
  });

  describe('On form submission', () => {
    it('emits a submit event', async () => {
      jest.spyOn(Utils, 'fetchPipelineConfigurationFileExists').mockReturnValue(true);

      const { name, description, pipelineConfigurationFullPath, color } = frameworkFoundResponse;
      wrapper = createComponent({ name, description, pipelineConfigurationFullPath, color });

      await findForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(wrapper.emitted('submit')).toHaveLength(1);
    });
  });

  describe('On pipeline configuration path input', () => {
    it('updates the pipelineConfigurationFullPath value and validates the path', async () => {
      jest.spyOn(Utils, 'fetchPipelineConfigurationFileExists').mockResolvedValue(true);

      wrapper = createComponent();

      await findPipelineConfigurationInput().vm.$emit('input', 'foo.yaml@bar/baz');

      expect(wrapper.emitted('update:pipelineConfigurationFullPath')[0][0]).toBe(
        'foo.yaml@bar/baz',
      );
      /* TODO: Test that debounce is called. Right now this isn't possible
       * because the lodash debounce function is mocked. We need to update the
       * mock to enable us to assert that a method is debounced.
       * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56013#note_524874122
       */
      expect(Utils.fetchPipelineConfigurationFileExists).toHaveBeenCalledWith('foo.yaml@bar/baz');
    });
  });

  describe('on cancelling', () => {
    it('should emit a cancel event', () => {
      wrapper = createComponent();

      findCancelBtn().vm.$emit('click', new MouseEvent('click'));

      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });
  });
});
