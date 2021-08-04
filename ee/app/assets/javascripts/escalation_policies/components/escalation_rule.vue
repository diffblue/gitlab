<script>
import {
  GlFormGroup,
  GlFormInput,
  GlDropdown,
  GlDropdownItem,
  GlCard,
  GlButton,
  GlIcon,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { ACTIONS, ALERT_STATUSES } from '../constants';

export const i18n = {
  fields: {
    rules: {
      condition: s__('EscalationPolicies|IF alert is not %{alertStatus} in %{minutes} minutes'),
      action: s__('EscalationPolicies|THEN %{doAction} %{schedule}'),
      selectSchedule: s__('EscalationPolicies|Select schedule'),
      noSchedules: s__(
        'EscalationPolicies|A schedule is required for adding an escalation policy. Please create an on-call schedule first.',
      ),
      removeRuleLabel: s__('EscalationPolicies|Remove escalation rule'),
      emptyScheduleValidationMsg: s__(
        'EscalationPolicies|A schedule is required for adding an escalation policy.',
      ),
      invalidTimeValidationMsg: s__('EscalationPolicies|Minutes must be between 0 and 1440.'),
    },
  },
};

export default {
  i18n,
  ALERT_STATUSES,
  ACTIONS,
  components: {
    GlFormGroup,
    GlFormInput,
    GlDropdown,
    GlDropdownItem,
    GlCard,
    GlButton,
    GlIcon,
    GlSprintf,
  },
  directives: {
    GlTooltip,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    schedules: {
      type: Array,
      required: false,
      default: () => [],
    },
    schedulesLoading: {
      type: Boolean,
      required: true,
      default: true,
    },
    index: {
      type: Number,
      required: true,
    },
    validationState: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    const { status, elapsedTimeMinutes, action, oncallScheduleIid } = this.rule;
    return {
      status,
      elapsedTimeMinutes,
      action,
      oncallScheduleIid,
    };
  },
  computed: {
    scheduleDropdownTitle() {
      return this.oncallScheduleIid
        ? this.schedules.find(({ iid }) => iid === this.oncallScheduleIid)?.name
        : i18n.fields.rules.selectSchedule;
    },
    noSchedules() {
      return !this.schedulesLoading && !this.schedules.length;
    },
    isValid() {
      return this.isTimeValid && this.isScheduleValid;
    },
    isTimeValid() {
      return this.validationState?.isTimeValid;
    },
    isScheduleValid() {
      return this.validationState?.isScheduleValid;
    },
  },
  methods: {
    setOncallSchedule({ iid }) {
      this.oncallScheduleIid = this.oncallScheduleIid === iid ? null : iid;
      this.emitUpdate();
    },
    setStatus(status) {
      this.status = status;
      this.emitUpdate();
    },
    emitUpdate() {
      this.$emit('update-escalation-rule', {
        index: this.index,
        rule: {
          oncallScheduleIid: parseInt(this.oncallScheduleIid, 10),
          action: this.action,
          status: this.status,
          elapsedTimeMinutes: this.elapsedTimeMinutes,
        },
      });
    },
  },
};
</script>

<template>
  <gl-card class="gl-border-gray-400 gl-bg-gray-10 gl-mb-3 gl-relative">
    <gl-button
      v-if="index !== 0"
      category="tertiary"
      size="small"
      icon="close"
      :aria-label="$options.i18n.fields.rules.removeRuleLabel"
      class="gl-absolute rule-close-icon"
      @click="$emit('remove-escalation-rule', index)"
    />
    <gl-form-group :state="isValid" class="gl-mb-0">
      <template #invalid-feedback>
        <div v-if="!isScheduleValid">
          {{ $options.i18n.fields.rules.emptyScheduleValidationMsg }}
        </div>
        <div v-if="!isTimeValid" class="gl-display-inline-block gl-mt-2">
          {{ $options.i18n.fields.rules.invalidTimeValidationMsg }}
        </div>
      </template>

      <div class="gl-display-flex gl-align-items-center">
        <gl-sprintf :message="$options.i18n.fields.rules.condition">
          <template #alertStatus>
            <gl-dropdown
              class="rule-control gl-mx-3"
              :text="$options.ALERT_STATUSES[status]"
              data-testid="alert-status-dropdown"
            >
              <gl-dropdown-item
                v-for="(label, alertStatus) in $options.ALERT_STATUSES"
                :key="alertStatus"
                :is-checked="status === alertStatus"
                is-check-item
                @click="setStatus(alertStatus)"
              >
                {{ label }}
              </gl-dropdown-item>
            </gl-dropdown>
          </template>
          <template #minutes>
            <gl-form-input
              v-model="elapsedTimeMinutes"
              class="gl-mx-3 gl-inset-border-1-gray-200! gl-w-12"
              number
              min="0"
              @input="emitUpdate"
            />
          </template>
        </gl-sprintf>
      </div>
      <div class="gl-display-flex gl-align-items-center gl-mt-3">
        <gl-sprintf :message="$options.i18n.fields.rules.action">
          <template #doAction>
            <gl-dropdown
              class="rule-control gl-mx-3"
              :text="$options.ACTIONS[rule.action]"
              data-testid="action-dropdown"
            >
              <gl-dropdown-item
                v-for="(label, ruleAction) in $options.ACTIONS"
                :key="ruleAction"
                :is-checked="rule.action === ruleAction"
                is-check-item
              >
                {{ label }}
              </gl-dropdown-item>
            </gl-dropdown>
          </template>
          <template #schedule>
            <gl-dropdown
              :disabled="noSchedules"
              class="rule-control"
              :text="scheduleDropdownTitle"
              data-testid="schedules-dropdown"
            >
              <template #button-text>
                <span :class="{ 'gl-text-gray-400': !oncallScheduleIid }">
                  {{ scheduleDropdownTitle }}
                </span>
              </template>
              <gl-dropdown-item
                v-for="schedule in schedules"
                :key="schedule.iid"
                :is-checked="schedule.iid === oncallScheduleIid"
                is-check-item
                @click="setOncallSchedule(schedule)"
              >
                {{ schedule.name }}
              </gl-dropdown-item>
            </gl-dropdown>
            <gl-icon
              v-if="noSchedules"
              v-gl-tooltip
              :title="$options.i18n.fields.rules.noSchedules"
              name="information-o"
              class="gl-text-gray-500 gl-ml-3"
              data-testid="no-schedules-info-icon"
            />
          </template>
        </gl-sprintf>
      </div>
    </gl-form-group>
  </gl-card>
</template>
