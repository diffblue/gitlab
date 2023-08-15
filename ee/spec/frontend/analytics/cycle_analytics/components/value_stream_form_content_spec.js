import { GlModal, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
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
  const initialFormNameErrors = { name: ['Name field required'] };
  const initialFormStageErrors = {
    stages: [
      {
        name: ['Name field is required'],
        endEventIdentifier: ['Please select a start event first'],
      },
    ],
  };
  const formSubmissionErrors = {
    name: ['has already been taken'],
    stages: [
      {
        name: ['has already been taken'],
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
  const findDefaultStages = () => findExtendedFormFields().findAllComponents(DefaultStageFields);
  const findCustomStages = () => findExtendedFormFields().findAllComponents(CustomStageFields);
  const findPresetSelector = () => wrapper.findByTestId('vsa-preset-selector');
  const findRestoreButton = () => wrapper.findByTestId('vsa-reset-button');
  const findRestoreStageButton = (index) => wrapper.findByTestId(`stage-action-restore-${index}`);
  const findHiddenStages = () => wrapper.findAllByTestId('vsa-hidden-stage').wrappers;
  const findBtn = (btn) => findModal().props(btn);
  const findCustomStageEventField = (index = 0) =>
    wrapper.findAllComponents(CustomStageEventField).at(index);
  const findFieldErrors = (testId) => wrapper.findByTestId(testId).attributes('invalid-feedback');
  const findNameInput = () =>
    wrapper.findByTestId('create-value-stream-name').findComponent(GlFormInput);

  const clickSubmit = () => findModal().vm.$emit('primary', mockEvent);
  const clickAddStage = () => findModal().vm.$emit('secondary', mockEvent);
  const clickRestoreStageAtIndex = (index) => findRestoreStageButton(index).vm.$emit('click');
  const expectFieldError = (testId, error = '') => expect(findFieldErrors(testId)).toBe(error);
  const expectCustomFieldError = (index, attr, error = '') =>
    expect(findCustomStageEventField(index).attributes(attr)).toBe(error);
  const expectStageTransitionKeys = (stages) =>
    stages.forEach((stage) => expect(stage.transitionKey).toContain('stage-'));

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

    it('renders the modal footer buttons', () => {
      expect(findModal().attributes('hide-footer')).toBeUndefined();
    });

    describe('Preset selector', () => {
      it('has the preset button', () => {
        expect(findPresetSelector().exists()).toBe(true);
      });

      it('will toggle between the blank and default templates', async () => {
        expect(findDefaultStages()).toHaveLength(defaultStageConfig.length);
        expect(findCustomStages()).toHaveLength(0);

        await findPresetSelector().vm.$emit('input', PRESET_OPTIONS_BLANK);

        expect(findDefaultStages()).toHaveLength(0);
        expect(findCustomStages()).toHaveLength(1);

        await findPresetSelector().vm.$emit('input', PRESET_OPTIONS_DEFAULT);

        expect(findDefaultStages()).toHaveLength(defaultStageConfig.length);
        expect(findCustomStages()).toHaveLength(0);
      });

      it('does not clear name when toggling templates', async () => {
        await findNameInput().vm.$emit('input', initialData.name);

        expect(findNameInput().attributes('value')).toBe(initialData.name);

        await findPresetSelector().vm.$emit('input', PRESET_OPTIONS_BLANK);

        expect(findNameInput().attributes('value')).toBe(initialData.name);

        await findPresetSelector().vm.$emit('input', PRESET_OPTIONS_DEFAULT);

        expect(findNameInput().attributes('value')).toBe(initialData.name);
      });

      it('each stage has a transition key when toggling', async () => {
        await findPresetSelector().vm.$emit('input', PRESET_OPTIONS_BLANK);

        expectStageTransitionKeys(wrapper.vm.stages);

        await findPresetSelector().vm.$emit('input', PRESET_OPTIONS_DEFAULT);

        expectStageTransitionKeys(wrapper.vm.stages);
      });

      it('does not display any hidden stages', () => {
        expect(findHiddenStages()).toHaveLength(0);
      });

      it('will fetch group labels', () => {
        expect(fetchGroupLabelsMock).toHaveBeenCalled();
      });
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
        expect(findDefaultStages()).toHaveLength(defaultStageConfig.length);
        expect(findCustomStages()).toHaveLength(0);

        await clickAddStage();

        expect(findDefaultStages()).toHaveLength(defaultStageConfig.length);
        expect(findCustomStages()).toHaveLength(1);
      });

      it('validates existing fields when clicked', async () => {
        const fieldTestId = 'create-value-stream-name';
        expect(findFieldErrors(fieldTestId)).toBeUndefined();

        await clickAddStage();

        expectFieldError(fieldTestId, 'Name is required');
      });

      it('each stage has a transition key', () => {
        expectStageTransitionKeys(wrapper.vm.stages);
      });
    });

    describe('initial form stage errors', () => {
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

      it('renders errors for a custom stage field', () => {
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

    describe('initial form name errors', () => {
      beforeEach(() => {
        wrapper = createComponent({
          props: {
            initialFormErrors: initialFormNameErrors,
          },
        });
      });

      it('renders errors for the name field', () => {
        expectFieldError('create-value-stream-name', initialFormNameErrors.name[0]);
      });
    });

    describe('with valid fields', () => {
      beforeEach(() => {
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      afterEach(() => {
        unmockTracking();
      });

      describe('form submitted successfully', () => {
        beforeEach(async () => {
          wrapper = createComponent();

          await findNameInput().vm.$emit('input', streamName);
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
          expect(findNameInput().attributes('value')).toBe('');
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
        beforeEach(async () => {
          wrapper = createComponent({
            props: {
              initialFormErrors: formSubmissionErrors,
            },
            stubs: {
              CustomStageFields,
            },
          });

          await findNameInput().vm.$emit('input', streamName);
          clickSubmit();
        });

        it('calls the createValueStream action', () => {
          expect(createValueStreamMock).toHaveBeenCalled();
        });

        it('does not clear the name field', () => {
          expect(findNameInput().attributes('value')).toBe(streamName);
        });

        it('does not display a toast message', () => {
          expect(mockToastShow).not.toHaveBeenCalled();
        });

        it('renders errors for the name field', () => {
          expectFieldError('create-value-stream-name', formSubmissionErrors.name[0]);
        });
      });
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
      expect(findHiddenStages()).toHaveLength(0);
    });

    it('each stage has a transition key', () => {
      expectStageTransitionKeys(wrapper.vm.stages);
    });

    describe('restore defaults button', () => {
      it('restores the original name', async () => {
        const newName = 'name';

        await findNameInput().vm.$emit('input', newName);

        expect(findNameInput().attributes('value')).toBe(newName);

        await findRestoreButton().vm.$emit('click');

        expect(findNameInput().attributes('value')).toBe(initialData.name);
      });

      it('will clear the form fields', async () => {
        expect(findCustomStages()).toHaveLength(stageCount);

        await clickAddStage();

        expect(findCustomStages()).toHaveLength(stageCount + 1);

        await findRestoreButton().vm.$emit('click');

        expect(findCustomStages()).toHaveLength(stageCount);
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
        expect(findHiddenStages()).toHaveLength(hiddenStages.length);

        findHiddenStages().forEach((s) => {
          expect(s.text()).toContain('Restore stage');
        });
      });

      it('when `Restore stage` is clicked, the stage is restored', async () => {
        expect(findHiddenStages()).toHaveLength(hiddenStages.length);
        expect(findDefaultStages()).toHaveLength(0);
        expect(findCustomStages()).toHaveLength(stageCount);

        await clickRestoreStageAtIndex(1);

        expect(findHiddenStages()).toHaveLength(hiddenStages.length - 1);
        expect(findDefaultStages()).toHaveLength(1);
        expect(findCustomStages()).toHaveLength(stageCount);
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
        expect(findCustomStages()).toHaveLength(stageCount);

        await clickAddStage();

        expect(findCustomStages()).toHaveLength(stageCount + 1);
      });

      it('validates existing fields when clicked', async () => {
        const fieldTestId = 'create-value-stream-name';
        expect(findFieldErrors(fieldTestId)).toBeUndefined();

        await findNameInput().vm.$emit('input', '');
        await clickAddStage();

        expectFieldError(fieldTestId, 'Name is required');
      });
    });

    describe('with valid fields', () => {
      beforeEach(() => {
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      afterEach(() => {
        unmockTracking();
      });

      describe('form submitted successfully', () => {
        beforeEach(() => {
          wrapper = createComponent({
            props: {
              initialPreset,
              initialData,
              isEditing: true,
            },
          });

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
            props: {
              initialFormErrors: formSubmissionErrors,
              initialData,
              initialPreset,
              isEditing: true,
            },
            stubs: {
              CustomStageFields,
            },
          });

          clickSubmit();
        });

        it('calls the updateValueStreamMock action', () => {
          expect(updateValueStreamMock).toHaveBeenCalled();
        });

        it('does not clear the name field', () => {
          const { name } = initialData;

          expect(findNameInput().attributes('value')).toBe(name);
        });

        it('does not display a toast message', () => {
          expect(mockToastShow).not.toHaveBeenCalled();
        });

        it('renders errors for the name field', () => {
          expectFieldError('create-value-stream-name', formSubmissionErrors.name[0]);
        });

        it('renders errors for a custom stage field', () => {
          expectFieldError('custom-stage-name-0', formSubmissionErrors.stages[0].name[0]);
        });
      });
    });
  });

  describe('isFetchingGroupLabels=true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        state: {
          defaultGroupLabels: [],
          isFetchingGroupLabels: true,
        },
      });
    });

    it('hides the modal footer buttons', () => {
      expect(findModal().attributes('hide-footer')).toBe('true');
    });
  });
});
