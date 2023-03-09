import { GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CustomStageFields from 'ee/analytics/cycle_analytics/components/create_value_stream_form/custom_stage_fields.vue';
import CustomStageEventField from 'ee/analytics/cycle_analytics/components/create_value_stream_form/custom_stage_event_field.vue';
import CustomStageEventLabelField from 'ee/analytics/cycle_analytics/components/create_value_stream_form/custom_stage_event_label_field.vue';
import StageFieldActions from 'ee/analytics/cycle_analytics/components/create_value_stream_form/stage_field_actions.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  customStageEvents as stageEvents,
  labelStartEvent,
  labelEndEvent,
  customStageEndEvents as endEvents,
  groupLabels as defaultGroupLabels,
} from '../../mock_data';
import { emptyState, emptyErrorsState, firstLabel } from './mock_data';

const formatStartEventOpts = (_events) => [
  { text: 'Select start event', value: null },
  ..._events
    .filter((ev) => ev.canBeStartEvent)
    .map(({ name: text, identifier: value }) => ({ text, value })),
];

const formatEndEventOpts = (_events) => [
  { text: 'Select end event', value: null },
  ..._events
    .filter((ev) => !ev.canBeStartEvent)
    .map(({ name: text, identifier: value }) => ({ text, value })),
];

const startEventOptions = formatStartEventOpts(stageEvents);
const endEventOptions = formatEndEventOpts(stageEvents);

describe('CustomStageFields', () => {
  function createComponent({
    stage = emptyState,
    errors = emptyErrorsState,
    stubs = {},
    props = {},
  } = {}) {
    return extendedWrapper(
      shallowMount(CustomStageFields, {
        propsData: {
          defaultGroupLabels,
          stage,
          errors,
          stageEvents,
          index: 0,
          totalStages: 3,
          stageLabel: 'Stage 1',
          ...props,
        },
        stubs: {
          'labels-selector': false,
          ...stubs,
        },
      }),
    );
  }

  let wrapper = null;

  const findName = (index = 0) => wrapper.findByTestId(`custom-stage-name-${index}`);
  const findStartEventLabel = (index = 0) =>
    wrapper.findByTestId(`custom-stage-start-event-label-${index}`);
  const findEndEventLabel = (index = 0) =>
    wrapper.findByTestId(`custom-stage-end-event-label-${index}`);
  const findNameField = () => findName().findComponent(GlFormInput);
  const findStartEventField = () => wrapper.findAllComponents(CustomStageEventField).at(0);
  const findEndEventField = () => wrapper.findAllComponents(CustomStageEventField).at(1);
  const findStartEventLabelField = () =>
    wrapper.findAllComponents(CustomStageEventLabelField).at(0);
  const findEndEventLabelField = () => wrapper.findAllComponents(CustomStageEventLabelField).at(1);
  const findStageFieldActions = () => wrapper.findComponent(StageFieldActions);

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe.each([
    ['Name', findNameField, undefined],
    ['Start event', findStartEventField, undefined],
    ['End event', findEndEventField, 'true'],
  ])('Default state', (field, finder, fieldDisabledValue) => {
    it(`field '${field}' is disabled ${fieldDisabledValue ? 'true' : 'false'}`, () => {
      const $el = finder();
      expect($el.exists()).toBe(true);
      expect($el.attributes('disabled')).toBe(fieldDisabledValue);
    });
  });

  describe.each([
    ['Start event label', findStartEventLabel],
    ['End event label', findEndEventLabel],
  ])('Default state', (field, finder) => {
    it(`field '${field}' is hidden by default`, () => {
      expect(finder().exists()).toBe(false);
    });
  });

  describe('Fields', () => {
    it('emit input event when a field is changed', () => {
      expect(wrapper.emitted('input')).toBeUndefined();
      findNameField().vm.$emit('input', 'Cool new stage');

      expect(wrapper.emitted('input')[0]).toEqual([{ field: 'name', value: 'Cool new stage' }]);
    });
  });

  describe('Start event', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('selects the correct start events for the start events dropdown', () => {
      expect(wrapper.vm.startEvents).toEqual(startEventOptions);
    });

    it('does not select end events for the start events dropdown', () => {
      expect(wrapper.vm.startEvents).not.toEqual(endEventOptions);
    });

    describe('start event label', () => {
      beforeEach(() => {
        wrapper = createComponent({
          stage: {
            startEventIdentifier: labelStartEvent.identifier,
          },
        });
      });

      it('will display the start event label field if a label event is selected', () => {
        expect(findStartEventLabelField().exists()).toEqual(true);
      });

      it('will emit the `input` event when the start event label field when selected', () => {
        expect(wrapper.emitted('input')).toBeUndefined();

        findStartEventLabelField().vm.$emit('update-label', firstLabel);

        expect(wrapper.emitted('input')[0]).toEqual([
          { field: 'startEventLabelId', value: firstLabel.id },
        ]);
      });
    });
  });

  describe('End event', () => {
    const possibleEndEvents = endEvents.filter((ev) =>
      labelStartEvent.allowedEndEvents.includes(ev.identifier),
    );

    const allowedEndEventOpts = formatEndEventOpts(possibleEndEvents);

    beforeEach(() => {
      wrapper = createComponent();
    });

    it('selects the end events based on the start event', () => {
      expect(wrapper.vm.endEvents).toEqual(allowedEndEventOpts);
    });

    it('does not select start events for the end events dropdown', () => {
      expect(wrapper.vm.endEvents).not.toEqual(startEventOptions);
    });

    describe('end event label', () => {
      beforeEach(() => {
        wrapper = createComponent({
          stage: {
            startEventIdentifier: labelStartEvent.identifier,
            endEventIdentifier: labelEndEvent.identifier,
          },
        });
      });

      it('will display the end event label field if a label event is selected', () => {
        expect(findEndEventLabelField().exists()).toEqual(true);
      });

      it('will emit the `input` event when the start event label field when selected', () => {
        expect(wrapper.emitted('input')).toBeUndefined();

        findEndEventLabelField().vm.$emit('update-label', firstLabel);

        expect(wrapper.emitted('input')[0]).toEqual([
          { field: 'endEventLabelId', value: firstLabel.id },
        ]);
      });
    });
  });

  describe('Stage actions', () => {
    it('will display the stage actions component', () => {
      expect(findStageFieldActions().exists()).toBe(true);
    });

    describe('with only 1 stage', () => {
      beforeEach(() => {
        wrapper = createComponent({ props: { totalStages: 1 } });
      });

      it('does not display the stage actions component', () => {
        expect(findStageFieldActions().exists()).toBe(false);
      });
    });
  });
});
