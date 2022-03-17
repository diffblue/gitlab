import { GlModal, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import {
  i18n,
  PRESET_OPTIONS_BLANK,
  PRESET_OPTIONS_DEFAULT,
} from 'ee/analytics/cycle_analytics/components/create_value_stream_form/constants';
import CustomStageFields from 'ee/analytics/cycle_analytics/components/create_value_stream_form/custom_stage_fields.vue';
import CustomStageEventField from 'ee/analytics/cycle_analytics/components/create_value_stream_form/custom_stage_event_field.vue';
import DefaultStageFields from 'ee/analytics/cycle_analytics/components/create_value_stream_form/default_stage_fields.vue';
import ValueStreamFormContent from 'ee/analytics/cycle_analytics/components/value_stream_form_content.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';
import {
  customStageEvents as formEvents,
  defaultStageConfig,
  rawCustomStage,
  groupLabels as defaultGroupLabels,
} from '../mock_data';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

Vue.use(Vuex);

describe('ValueStreamFormContent', () => {
  let wrapper = null;
  let trackingSpy = null;

  const createValueStreamMock = jest.fn(() => Promise.resolve());
  const updateValueStreamMock = jest.fn(() => Promise.resolve());
  const fetchGroupLabelsMock = jest.fn(() => Promise.resolve());
  const mockEvent = { preventDefault: jest.fn() };
  const mockToastShow = jest.fn();
  const streamName = 'Cool stream';
  const initialFormErrors = { name: ['Name field required'] };
  const initialFormStageErrors = {
    stages: [
      {
        name: ['Name field is required'],
        endEventIdentifier: ['Please select a start event first'],
      },
    ],
  };

  const initialData = {
    stages: [convertObjectPropsToCamelCase(rawCustomStage)],
    id: 1337,
    name: 'Editable value stream',
  };

  const initialPreset = PRESET_OPTIONS_DEFAULT;

  const fakeStore = ({ state }) =>
    new Vuex.Store({
      state: {
        isCreatingValueStream: false,
        formEvents,
        defaultGroupLabels,
        ...state,
      },
      actions: {
        createValueStream: createValueStreamMock,
        updateValueStream: updateValueStreamMock,
        fetchGroupLabels: fetchGroupLabelsMock,
      },
    });

  const createComponent = ({ props = {}, data = {}, stubs = {}, state = {} } = {}) =>
    extendedWrapper(
      shallowMount(ValueStreamFormContent, {
        store: fakeStore({ state }),
        data() {
          return {
            ...data,
          };
        },
        propsData: {
          defaultStageConfig,
          ...props,
        },
        mocks: {
          $toast: {
            show: mockToastShow,
          },
        },
        stubs: {
          ...stubs,
        },
      }),
    );

  const findModal = () => wrapper.findComponent(GlModal);
  const findExtendedFormFields = () => wrapper.findByTestId('extended-form-fields');
  const findPresetSelector = () => wrapper.findByTestId('vsa-preset-selector');
  const findRestoreButton = () => wrapper.findByTestId('vsa-reset-button');
  const findRestoreStageButton = (index) => wrapper.findByTestId(`stage-action-restore-${index}`);
  const findHiddenStages = () => wrapper.findAllByTestId('vsa-hidden-stage').wrappers;
  const findBtn = (btn) => findModal().props(btn);
  const findCustomStageEventField = (index = 0) =>
    wrapper.findAllComponents(CustomStageEventField).at(index);

  const clickSubmit = () => findModal().vm.$emit('primary', mockEvent);
  const clickAddStage = () => findModal().vm.$emit('secondary', mockEvent);
  const clickRestoreStageAtIndex = (index) => findRestoreStageButton(index).vm.$emit('click');
  const expectFieldError = (testId, error = '') =>
    expect(wrapper.findByTestId(testId).attributes('invalid-feedback')).toBe(error);
  const expectCustomFieldError = (index, attr, error = '') =>
    expect(findCustomStageEventField(index).attributes(attr)).toBe(error);
  const expectStageTransitionKeys = (stages) =>
    stages.forEach((stage) => expect(stage.transitionKey).toContain('stage-'));

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createComponent({ state: { defaultGroupLabels: null } });
    });

    it('has the extended fields', () => {
      expect(findExtendedFormFields().exists()).toBe(true);
    });

    it('sets the submit action text to "Create Value Stream"', () => {
      expect(findBtn('actionPrimary').text).toBe(i18n.FORM_TITLE);
    });

    describe('Preset selector', () => {
      it('has the preset button', () => {
        expect(findPresetSelector().exists()).toBe(true);
      });

      it('will toggle between the blank and default templates', () => {
        expect(wrapper.vm.stages).toHaveLength(defaultStageConfig.length);

        findPresetSelector().vm.$emit('input', PRESET_OPTIONS_BLANK);

        expect(wrapper.vm.stages).toHaveLength(1);

        findPresetSelector().vm.$emit('input', PRESET_OPTIONS_DEFAULT);

        expect(wrapper.vm.stages).toHaveLength(defaultStageConfig.length);
      });
    });

    it('each stage has a transition key when toggling', () => {
      findPresetSelector().vm.$emit('input', PRESET_OPTIONS_BLANK);

      expectStageTransitionKeys(wrapper.vm.stages);

      findPresetSelector().vm.$emit('input', PRESET_OPTIONS_DEFAULT);

      expectStageTransitionKeys(wrapper.vm.stages);
    });

    it('does not display any hidden stages', () => {
      expect(findHiddenStages().length).toBe(0);
    });

    it('will fetch group labels', () => {
      expect(fetchGroupLabelsMock).toHaveBeenCalled();
    });

    describe('Add stage button', () => {
      beforeEach(() => {
        wrapper = createComponent({
          stubs: {
            CustomStageFields,
          },
        });
      });

      it('has the add stage button', () => {
        expect(findBtn('actionSecondary')).toMatchObject({ text: 'Add another stage' });
      });

      it('adds a blank custom stage when clicked', async () => {
        expect(wrapper.vm.stages).toHaveLength(defaultStageConfig.length);

        await clickAddStage();

        expect(wrapper.vm.stages.length).toBe(defaultStageConfig.length + 1);
      });

      it('validates existing fields when clicked', async () => {
        expect(wrapper.vm.nameError).toHaveLength(0);

        await clickAddStage();

        expect(wrapper.vm.nameError).toEqual(['Name is required']);
      });

      it('each stage has a transition key', () => {
        expectStageTransitionKeys(wrapper.vm.stages);
      });
    });

    describe('form errors', () => {
      const commonExtendedData = {
        props: {
          initialFormErrors: initialFormStageErrors,
        },
      };

      it('renders errors for a default stage field', () => {
        wrapper = createComponent({
          ...commonExtendedData,
          stubs: {
            DefaultStageFields,
          },
        });

        expectFieldError('default-stage-name-0', initialFormStageErrors.stages[0].name[0]);
      });

      it('renders errors for a custom stage field', async () => {
        wrapper = createComponent({
          props: {
            ...commonExtendedData.props,
            initialPreset: PRESET_OPTIONS_BLANK,
          },
          stubs: {
            CustomStageFields,
          },
        });

        expectFieldError('custom-stage-name-0', initialFormStageErrors.stages[0].name[0]);
        expectCustomFieldError(
          1,
          'identifiererror',
          initialFormStageErrors.stages[0].endEventIdentifier[0],
        );
      });
    });

    describe('isEditing=true', () => {
      const stageCount = initialData.stages.length;
      beforeEach(() => {
        wrapper = createComponent({
          props: {
            initialPreset,
            initialData,
            isEditing: true,
          },
        });
      });

      it('does not have the preset button', () => {
        expect(findPresetSelector().exists()).toBe(false);
      });

      it('sets the submit action text to "Save value stream"', () => {
        expect(findBtn('actionPrimary').text).toBe(i18n.EDIT_FORM_ACTION);
      });

      it('does not display any hidden stages', () => {
        expect(findHiddenStages().length).toBe(0);
      });

      it('each stage has a transition key', () => {
        expectStageTransitionKeys(wrapper.vm.stages);
      });

      describe('restore defaults button', () => {
        it('will clear the form fields', async () => {
          expect(wrapper.vm.stages).toHaveLength(stageCount);

          await clickAddStage();

          expect(wrapper.vm.stages).toHaveLength(stageCount + 1);

          findRestoreButton().vm.$emit('click');

          expect(wrapper.vm.stages).toHaveLength(stageCount);
        });
      });

      describe('with hidden stages', () => {
        const hiddenStages = defaultStageConfig.map((s) => ({ ...s, hidden: true }));

        beforeEach(() => {
          wrapper = createComponent({
            props: {
              initialPreset,
              initialData: { ...initialData, stages: [...initialData.stages, ...hiddenStages] },
              isEditing: true,
            },
          });
        });

        it('displays hidden each stage', () => {
          expect(findHiddenStages().length).toBe(hiddenStages.length);

          findHiddenStages().forEach((s) => {
            expect(s.text()).toContain('Restore stage');
          });
        });

        it('when `Restore stage` is clicked, the stage is restored', async () => {
          await clickRestoreStageAtIndex(1);

          expect(findHiddenStages().length).toBe(hiddenStages.length - 1);
          expect(wrapper.vm.stages.length).toBe(stageCount + 1);
        });

        it('when a stage is restored it has a transition key', async () => {
          await clickRestoreStageAtIndex(1);

          expect(wrapper.vm.stages[stageCount].transitionKey).toContain(
            `stage-${hiddenStages[1].name}-`,
          );
        });
      });

      describe('Add stage button', () => {
        beforeEach(() => {
          wrapper = createComponent({
            props: {
              initialPreset,
              initialData,
              isEditing: true,
            },
            stubs: {
              CustomStageFields,
            },
          });
        });

        it('has the add stage button', () => {
          expect(findBtn('actionSecondary')).toMatchObject({ text: i18n.BTN_ADD_ANOTHER_STAGE });
        });

        it('adds a blank custom stage when clicked', async () => {
          expect(wrapper.vm.stages.length).toBe(stageCount);

          await clickAddStage();

          expect(wrapper.vm.stages.length).toBe(stageCount + 1);
        });

        it('validates existing fields when clicked', async () => {
          expect(wrapper.vm.nameError).toEqual([]);

          wrapper
            .findByTestId('create-value-stream-name')
            .findComponent(GlFormInput)
            .vm.$emit('input', '');
          await clickAddStage();

          expect(wrapper.vm.nameError).toEqual(['Name is required']);
        });
      });

      describe('with valid fields', () => {
        beforeEach(() => {
          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
          wrapper = createComponent({
            props: {
              initialPreset,
              initialData,
              isEditing: true,
            },
          });
        });

        afterEach(() => {
          unmockTracking();
          wrapper.destroy();
        });

        describe('form submitted successfully', () => {
          beforeEach(() => {
            clickSubmit();
          });

          it('calls the "updateValueStreamMock" event when submitted', () => {
            expect(updateValueStreamMock).toHaveBeenCalledWith(expect.any(Object), {
              ...initialData,
              stages: initialData.stages.map((stage) =>
                convertObjectPropsToSnakeCase(stage, { deep: true }),
              ),
            });
          });

          it('displays a toast message', () => {
            expect(mockToastShow).toHaveBeenCalledWith(`'${initialData.name}' Value Stream saved`);
          });

          it('sends tracking information', () => {
            expect(trackingSpy).toHaveBeenCalledWith(undefined, 'submit_form', {
              label: 'edit_value_stream',
            });
          });
        });

        describe('form submission fails', () => {
          beforeEach(() => {
            wrapper = createComponent({
              data: { name: streamName },
              props: {
                initialFormErrors,
              },
            });

            clickSubmit();
          });

          it('does not call the updateValueStreamMock action', () => {
            expect(updateValueStreamMock).not.toHaveBeenCalled();
          });

          it('does not clear the name field', () => {
            expect(wrapper.vm.name).toBe(streamName);
          });

          it('does not display a toast message', () => {
            expect(mockToastShow).not.toHaveBeenCalled();
          });
        });
      });
    });
  });

  describe('defaultGroupLabels set', () => {
    beforeEach(() => {
      wrapper = createComponent({
        state: { defaultGroupLabels: [] },
      });
    });

    it('does not fetch group labels', () => {
      expect(fetchGroupLabelsMock).not.toHaveBeenCalled();
    });
  });

  describe('form errors', () => {
    beforeEach(() => {
      wrapper = createComponent({
        data: { name: '' },
        props: {
          initialFormErrors,
        },
      });
    });

    it('renders errors for the name field', () => {
      expectFieldError('create-value-stream-name', initialFormErrors.name[0]);
    });
  });

  describe('with valid fields', () => {
    beforeEach(() => {
      wrapper = createComponent({ data: { name: streamName } });
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
      wrapper.destroy();
    });

    describe('form submitted successfully', () => {
      beforeEach(() => {
        clickSubmit();
      });

      it('calls the "createValueStream" event when submitted', () => {
        expect(createValueStreamMock).toHaveBeenCalledWith(expect.any(Object), {
          name: streamName,
          stages: [
            {
              custom: false,
              name: 'issue',
            },
            {
              custom: false,
              name: 'plan',
            },
            {
              custom: false,
              name: 'code',
            },
          ],
        });
      });

      it('clears the name field', () => {
        expect(wrapper.vm.name).toBe('');
      });

      it('displays a toast message', () => {
        expect(mockToastShow).toHaveBeenCalledWith(`'${streamName}' Value Stream created`);
      });

      it('sends tracking information', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'submit_form', {
          label: 'create_value_stream',
        });
      });
    });

    describe('form submission fails', () => {
      beforeEach(() => {
        wrapper = createComponent({
          data: { name: streamName },
          props: {
            initialFormErrors,
          },
        });

        clickSubmit();
      });

      it('calls the createValueStream action', () => {
        expect(createValueStreamMock).toHaveBeenCalled();
      });

      it('does not clear the name field', () => {
        expect(wrapper.vm.name).toBe(streamName);
      });

      it('does not display a toast message', () => {
        expect(mockToastShow).not.toHaveBeenCalled();
      });
    });
  });
});
