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
import { ACTIONS, ALERT_STATUSES, EMAIL_ONCALL_SCHEDULE_USER, EMAIL_USER } from '../constants';
import UserSelect from './user_select.vue';

export const i18n = {
  fields: {
    rules: {
      condition: s__('EscalationPolicies|IF alert is not %{alertStatus} in %{minutes} minutes'),
      action: s__('EscalationPolicies|THEN %{doAction} %{scheduleOrUser}'),
      selectSchedule: s__('EscalationPolicies|Select schedule'),
      noSchedules: s__(
        'EscalationPolicies|A schedule is required for adding an escalation policy. Please create an on-call schedule first.',
      ),
      removeRuleLabel: s__('EscalationPolicies|Remove escalation rule'),
      emptyScheduleValidationMsg: s__(
        'EscalationPolicies|A schedule is required for adding an escalation policy.',
      ),
      invalidTimeValidationMsg: s__('EscalationPolicies|Minutes must be between 0 and 1440.'),
      invalidUserValidationMsg: s__(
        'EscalationPolicies|A user is required for adding an escalation policy.',
      ),
    },
  },
};

export default {
  i18n,
  ALERT_STATUSES,
  ACTIONS,
  EMAIL_ONCALL_SCHEDULE_USER,
  EMAIL_USER,
  components: {
    GlFormGroup,
    GlFormInput,
    GlDropdown,
    GlDropdownItem,
    GlCard,
    GlButton,
    GlIcon,
    GlSprintf,
    UserSelect,
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
    mappedParticipants: {
      type: Array,
      required: true,
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
    const { status, elapsedTimeMinutes, oncallScheduleIid, username, action } = this.rule;

    return {
      status,
      action,
      elapsedTimeMinutes,
      oncallScheduleIid,
      username,
      hasFocus: true,
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
      return this.isTimeValid && this.isScheduleValid && this.isUserValid;
    },
    isTimeValid() {
      return this.validationState?.isTimeValid;
    },
    isScheduleValid() {
      return this.validationState?.isScheduleValid;
    },
    isUserValid() {
      return this.validationState?.isUserValid;
    },
    isEmailOncallScheduleUserActionSelected() {
      return this.action === EMAIL_ONCALL_SCHEDULE_USER;
    },
    isEmailUserActionSelected() {
      return this.action === EMAIL_USER;
    },
    actionBasedRequestParams() {
      if (this.isEmailOncallScheduleUserActionSelected) {
        return { oncallScheduleIid: parseInt(this.oncallScheduleIid, 10) };
      }

      return { username: this.username };
    },
    showEmptyScheduleValidationMsg() {
      return this.isEmailOncallScheduleUserActionSelected && !this.isScheduleValid;
    },
    showNoUserValidationMsg() {
      return this.isEmailUserActionSelected && !this.isUserValid;
    },
  },
  mounted() {
    this.ruleContainer = this.$refs.ruleContainer?.$el;
    this.ruleContainer?.addEventListener('focusin', this.addFocus);
    this.ruleContainer?.addEventListener('focusout', this.removeFocus);
  },
  beforeDestroy() {
    this.ruleContainer?.removeEventListener('focusin', this.addFocus);
    this.ruleContainer?.removeEventListener('focusout', this.removeFocus);
  },
  methods: {
    addFocus() {
      this.hasFocus = true;
    },
    removeFocus() {
      this.hasFocus = false;
    },
    setOncallSchedule({ iid }) {
      this.oncallScheduleIid = this.oncallScheduleIid === iid ? null : iid;
      this.emitUpdate();
    },
    setAction(action) {
      this.action = action;
      if (this.isEmailOncallScheduleUserActionSelected) {
        this.username = null;
      } else if (this.isEmailUserActionSelected) {
        this.oncallScheduleIid = null;
      }
      this.emitUpdate();
    },
    setStatus(status) {
      this.status = status;
      this.emitUpdate();
    },
    setSelectedUser(username) {
      this.username = username;
      this.emitUpdate();
    },
    emitUpdate() {
      this.$emit('update-escalation-rule', {
        index: this.index,
        rule: {
          ...this.actionBasedRequestParams,
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
  <gl-card ref="ruleContainer" class="gl-border-gray-400 gl-bg-gray-10 gl-mb-3 gl-relative">
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
        <div v-if="!isScheduleValid && !hasFocus">
          {{ $options.i18n.fields.rules.emptyScheduleValidationMsg }}
        </div>
        <div v-if="!isUserValid && !hasFocus" class="gl-display-inline-block gl-mt-2">
          {{ $options.i18n.fields.rules.invalidUserValidationMsg }}
        </div>
        <div v-if="!isTimeValid && !hasFocus" class="gl-display-inline-block gl-mt-2">
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
              :text="$options.ACTIONS[action]"
              data-testid="action-dropdown"
            >
              <gl-dropdown-item
                v-for="(label, ruleAction) in $options.ACTIONS"
                :key="ruleAction"
                :is-checked="action === ruleAction"
                is-check-item
                @click="setAction(ruleAction)"
              >
                {{ label }}
              </gl-dropdown-item>
            </gl-dropdown>
          </template>
          <template #scheduleOrUser>
            <template v-if="isEmailOncallScheduleUserActionSelected">
              <gl-dropdown
                :disabled="noSchedules"
                class="rule-control"
                :text="scheduleDropdownTitle"
                data-testid="schedules-dropdown"
                data-qa-selector="schedule_dropdown"
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
            <user-select
              v-else
              :selected-user-name="username"
              :mapped-participants="mappedParticipants"
              @select-user="setSelectedUser"
            />
          </template>
        </gl-sprintf>
      </div>
    </gl-form-group>
  </gl-card>
</template>
