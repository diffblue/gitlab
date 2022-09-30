<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { isLabelEvent, getLabelEventsIdentifiers } from '../../utils';
import { i18n } from './constants';
import CustomStageEventField from './custom_stage_event_field.vue';
import CustomStageEventLabelField from './custom_stage_event_label_field.vue';
import StageFieldActions from './stage_field_actions.vue';
import { startEventOptions, endEventOptions } from './utils';

const findLabelNames = (labels = [], selectedLabelId) =>
  labels.filter(({ id }) => id === selectedLabelId).map(({ title }) => title);

export default {
  name: 'CustomStageFields',
  components: {
    GlFormGroup,
    GlFormInput,
    CustomStageEventField,
    CustomStageEventLabelField,
    StageFieldActions,
  },
  props: {
    index: {
      type: Number,
      required: true,
    },
    stageLabel: {
      type: String,
      required: true,
    },
    totalStages: {
      type: Number,
      required: true,
    },
    stage: {
      type: Object,
      required: true,
    },
    errors: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    stageEvents: {
      type: Array,
      required: true,
    },
    defaultGroupLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      labelEvents: getLabelEventsIdentifiers(this.stageEvents),
    };
  },
  computed: {
    startEvents() {
      return startEventOptions(this.stageEvents);
    },
    endEvents() {
      return endEventOptions(this.stageEvents, this.stage.startEventIdentifier);
    },
    hasStartEvent() {
      return this.stage.startEventIdentifier;
    },
    startEventRequiresLabel() {
      return isLabelEvent(this.labelEvents, this.stage.startEventIdentifier);
    },
    endEventRequiresLabel() {
      return isLabelEvent(this.labelEvents, this.stage.endEventIdentifier);
    },
    hasMultipleStages() {
      return this.totalStages > 1;
    },
    selectedStartEventName() {
      return this.eventName(this.stage.startEventIdentifier, 'SELECT_START_EVENT');
    },
    selectedEndEventName() {
      return this.eventName(this.stage.endEventIdentifier, 'SELECT_END_EVENT');
    },
    startEventLabelNames() {
      return findLabelNames(this.defaultGroupLabels, this.stage.startEventLabelId);
    },
    endEventLabelNames() {
      return findLabelNames(this.defaultGroupLabels, this.stage.endEventLabelId);
    },
  },
  methods: {
    onSelectLabel(field, event) {
      const { id: value = null } = event;
      this.$emit('input', { field, value });
    },
    hasFieldErrors(key) {
      return !Object.keys(this.errors).length || this.errors[key]?.length < 1;
    },
    fieldErrorMessage(key) {
      return this.errors[key]?.join('\n');
    },
    eventNameByIdentifier(identifier) {
      const ev = this.stageEvents.find((e) => e.identifier === identifier);
      return ev?.name || null;
    },
    eventName(eventId, textKey) {
      return eventId ? this.eventNameByIdentifier(eventId) : this.$options.i18n[textKey];
    },
  },
  i18n,
};
</script>
<template>
  <div data-testid="value-stream-stage-fields">
    <div class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row">
      <div class="gl-flex-grow-1 gl-mr-2">
        <gl-form-group
          :label="stageLabel"
          :state="hasFieldErrors('name')"
          :invalid-feedback="fieldErrorMessage('name')"
          :data-testid="`custom-stage-name-${index}`"
        >
          <!-- eslint-disable vue/no-mutating-props -->
          <gl-form-input
            v-model.trim="stage.name"
            :name="`custom-stage-name-${index}`"
            :placeholder="$options.i18n.FORM_FIELD_STAGE_NAME_PLACEHOLDER"
            required
            @input="$emit('input', { field: 'name', value: $event })"
          />
          <!-- eslint-enable vue/no-mutating-props -->
        </gl-form-group>
        <div class="gl-display-flex gl-justify-content-between gl-mt-3">
          <custom-stage-event-field
            event-type="start-event"
            :index="index"
            :field-label="$options.i18n.FORM_FIELD_START_EVENT"
            :selected-event-name="selectedStartEventName"
            :events-list="startEvents"
            :identifier-error="fieldErrorMessage('startEventIdentifier')"
            :has-identifier-error="hasFieldErrors('startEventIdentifier')"
            @update-identifier="$emit('input', { field: 'startEventIdentifier', value: $event })"
          />
          <custom-stage-event-label-field
            event-type="start-event"
            :index="index"
            :field-label="$options.i18n.FORM_FIELD_START_EVENT_LABEL"
            :requires-label="startEventRequiresLabel"
            :label-error="fieldErrorMessage('startEventLabelId')"
            :has-label-error="hasFieldErrors('startEventLabelId')"
            :selected-label-names="startEventLabelNames"
            @update-label="onSelectLabel('startEventLabelId', $event)"
          />
        </div>
        <div class="gl-display-flex gl-justify-content-between">
          <custom-stage-event-field
            event-type="end-event"
            :index="index"
            :disabled="!hasStartEvent"
            :field-label="$options.i18n.FORM_FIELD_END_EVENT"
            :selected-event-name="selectedEndEventName"
            :events-list="endEvents"
            :identifier-error="fieldErrorMessage('endEventIdentifier')"
            :has-identifier-error="hasFieldErrors('endEventIdentifier')"
            @update-identifier="$emit('input', { field: 'endEventIdentifier', value: $event })"
          />
          <custom-stage-event-label-field
            event-type="end-event"
            :index="index"
            :field-label="$options.i18n.FORM_FIELD_END_EVENT_LABEL"
            :requires-label="endEventRequiresLabel"
            :label-error="fieldErrorMessage('endEventLabelId')"
            :has-label-error="hasFieldErrors('endEventLabelId')"
            :selected-label-names="endEventLabelNames"
            @update-label="onSelectLabel('endEventLabelId', $event)"
          />
        </div>
      </div>
      <stage-field-actions
        v-if="hasMultipleStages"
        class="gl-mt-0 gl-sm-mt-6!"
        :index="index"
        :stage-count="totalStages"
        :can-remove="true"
        @move="$emit('move', $event)"
        @remove="$emit('remove', $event)"
      />
    </div>
  </div>
</template>
