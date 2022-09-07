<script>
import { GlFormGroup, GlFormInput, GlFormText } from '@gitlab/ui';
import { i18n, ADDITIONAL_DEFAULT_STAGE_EVENTS } from './constants';
import StageFieldActions from './stage_field_actions.vue';

const findStageEvent = (stageEvents = [], eid = null) => {
  if (!eid) return '';
  return stageEvents.find(({ identifier }) => identifier === eid);
};

const eventIdToName = (stageEvents = [], eid) => {
  const event = findStageEvent(stageEvents, eid);
  return event?.name || '';
};

export default {
  name: 'DefaultStageFields',
  components: {
    StageFieldActions,
    GlFormGroup,
    GlFormInput,
    GlFormText,
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
  },
  methods: {
    isValid(field) {
      return !this.errors[field] || !this.errors[field]?.length;
    },
    renderError(field) {
      return this.errors[field] ? this.errors[field]?.join('\n') : null;
    },
    eventName(eventId) {
      return eventIdToName([...this.stageEvents, ...ADDITIONAL_DEFAULT_STAGE_EVENTS], eventId);
    },
  },
  i18n,
};
</script>
<template>
  <div class="gl-mb-4" data-testid="value-stream-stage-fields">
    <div class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row">
      <div class="gl-flex-grow-1 gl-mr-2">
        <gl-form-group
          :label="stageLabel"
          :state="isValid('name')"
          :invalid-feedback="renderError('name')"
          :data-testid="`default-stage-name-${index}`"
          :description="$options.i18n.DEFAULT_STAGE_FEATURES"
        >
          <!-- eslint-disable vue/no-mutating-props -->
          <gl-form-input
            v-model.trim="stage.name"
            :name="`create-value-stream-stage-${index}`"
            :placeholder="$options.i18n.FORM_FIELD_STAGE_NAME_PLACEHOLDER"
            disabled="disabled"
            required
          />
          <!-- eslint-enable vue/no-mutating-props -->
        </gl-form-group>
        <div
          class="gl-display-flex gl-align-items-center"
          :data-testid="`stage-start-event-${index}`"
        >
          <span class="gl-m-0 gl-vertical-align-middle gl-mr-2 gl-font-weight-bold">{{
            $options.i18n.DEFAULT_FIELD_START_EVENT_LABEL
          }}</span>
          <gl-form-text class="gl-m-0" tag="span">{{
            eventName(stage.startEventIdentifier)
          }}</gl-form-text>
        </div>
        <div
          class="gl-display-flex gl-align-items-center"
          :data-testid="`stage-end-event-${index}`"
        >
          <span class="gl-m-0 gl-vertical-align-middle gl-mr-2 gl-font-weight-bold">{{
            $options.i18n.DEFAULT_FIELD_END_EVENT_LABEL
          }}</span>
          <gl-form-text class="gl-m-0" tag="span">{{
            eventName(stage.endEventIdentifier)
          }}</gl-form-text>
        </div>
      </div>
      <stage-field-actions
        class="gl-mt-3 gl-sm-mt-6!"
        :index="index"
        :stage-count="totalStages"
        @move="$emit('move', $event)"
        @hide="$emit('hide', $event)"
      />
    </div>
  </div>
</template>
