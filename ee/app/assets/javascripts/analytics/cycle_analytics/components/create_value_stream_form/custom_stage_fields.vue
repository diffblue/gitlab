<script>
import { GlFormGroup, GlFormInput, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { isLabelEvent, getLabelEventsIdentifiers, uniqById } from '../../utils';
import LabelsSelector from '../labels_selector.vue';
import { i18n } from './constants';
import StageFieldActions from './stage_field_actions.vue';
import { startEventOptions, endEventOptions } from './utils';

export default {
  name: 'CustomStageFormFields',
  components: {
    GlFormGroup,
    GlFormInput,
    GlDropdown,
    GlDropdownItem,
    LabelsSelector,
    StageFieldActions,
  },
  props: {
    index: {
      type: Number,
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
    initialGroupLabels() {
      return uniqById(
        [
          this.stage.startEventLabelId ? this.stage.startEventLabel : null,
          this.stage.endEventLabelId ? this.stage.endEventLabel : null,
          ...this.defaultGroupLabels,
        ].filter((l) => Boolean(l)),
      );
    },
  },
  methods: {
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
    <div class="gl-display-flex">
      <gl-form-group
        class="gl-flex-grow-1"
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
      <stage-field-actions
        v-if="hasMultipleStages"
        :index="index"
        :stage-count="totalStages"
        :can-remove="true"
        @move="$emit('move', $event)"
        @remove="$emit('remove', $event)"
      />
    </div>
    <div class="gl-display-flex gl-justify-content-between">
      <gl-form-group
        :data-testid="`custom-stage-start-event-${index}`"
        class="gl-w-half gl-mr-2"
        :label="$options.i18n.FORM_FIELD_START_EVENT"
        :state="hasFieldErrors('startEventIdentifier')"
        :invalid-feedback="fieldErrorMessage('startEventIdentifier')"
      >
        <gl-dropdown
          toggle-class="gl-mb-0"
          :text="selectedStartEventName"
          :name="`custom-stage-start-id-${index}`"
          menu-class="gl-overflow-hidden!"
          block
        >
          <gl-dropdown-item
            v-for="{ text, value } in startEvents"
            :key="`start-event-${value}`"
            :value="value"
            @click="$emit('input', { field: 'startEventIdentifier', value })"
            >{{ text }}</gl-dropdown-item
          >
        </gl-dropdown>
      </gl-form-group>
      <div class="gl-w-half gl-ml-2">
        <transition name="fade">
          <gl-form-group
            v-if="startEventRequiresLabel"
            :data-testid="`custom-stage-start-event-label-${index}`"
            :label="$options.i18n.FORM_FIELD_START_EVENT_LABEL"
            :state="hasFieldErrors('startEventLabelId')"
            :invalid-feedback="fieldErrorMessage('startEventLabelId')"
          >
            <labels-selector
              :initial-data="initialGroupLabels"
              :selected-label-ids="[stage.startEventLabelId]"
              :name="`custom-stage-start-label-${index}`"
              @select-label="$emit('input', { field: 'startEventLabelId', value: $event })"
            />
          </gl-form-group>
        </transition>
      </div>
    </div>
    <div class="gl-display-flex gl-justify-content-between">
      <gl-form-group
        :data-testid="`custom-stage-end-event-${index}`"
        class="gl-w-half gl-mr-2"
        :label="$options.i18n.FORM_FIELD_END_EVENT"
        :state="hasFieldErrors('endEventIdentifier')"
        :invalid-feedback="fieldErrorMessage('endEventIdentifier')"
      >
        <gl-dropdown
          toggle-class="gl-mb-0"
          :text="selectedEndEventName"
          :name="`custom-stage-end-id-${index}`"
          :disabled="!hasStartEvent"
          menu-class="gl-overflow-hidden!"
          block
        >
          <gl-dropdown-item
            v-for="{ text, value } in endEvents"
            :key="`end-event-${value}`"
            :value="value"
            @click="$emit('input', { field: 'endEventIdentifier', value })"
            >{{ text }}</gl-dropdown-item
          >
        </gl-dropdown>
      </gl-form-group>
      <div class="gl-w-half gl-ml-2">
        <transition name="fade">
          <gl-form-group
            v-if="endEventRequiresLabel"
            :data-testid="`custom-stage-end-event-label-${index}`"
            :label="$options.i18n.FORM_FIELD_END_EVENT_LABEL"
            :state="hasFieldErrors('endEventLabelId')"
            :invalid-feedback="fieldErrorMessage('endEventLabelId')"
          >
            <labels-selector
              :initial-data="initialGroupLabels"
              :selected-label-ids="[stage.endEventLabelId]"
              :name="`custom-stage-end-label-${index}`"
              @select-label="$emit('input', { field: 'endEventLabelId', value: $event })"
            />
          </gl-form-group>
        </transition>
      </div>
    </div>
  </div>
</template>
