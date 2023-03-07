<script>
import {
  GlModalDirective,
  GlTooltipDirective,
  GlButton,
  GlButtonGroup,
  GlCard,
  GlSprintf,
  GlIcon,
  GlCollapse,
  GlToken,
  GlAvatar,
} from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import {
  ACTIONS,
  ALERT_STATUSES,
  EMAIL_ONCALL_SCHEDULE_USER,
  deleteEscalationPolicyModalId,
  editEscalationPolicyModalId,
  EMAIL_USER,
} from '../constants';
import { getParticipantsWithTokenStyles, getEscalationUserIndex } from '../utils';
import EditEscalationPolicyModal from './add_edit_escalation_policy_modal.vue';
import DeleteEscalationPolicyModal from './delete_escalation_policy_modal.vue';

export const i18n = {
  editPolicy: s__('EscalationPolicies|Edit escalation policy'),
  deletePolicy: s__('EscalationPolicies|Delete escalation policy'),
  escalationRuleCondition: s__(
    'EscalationPolicies|%{clockIcon} IF alert is not %{alertStatus} in %{minutes}',
  ),
  escalationRuleAction: s__(
    'EscalationPolicies|%{notificationIcon} THEN %{doAction} %{forScheduleOrUser}',
  ),
  minutes: s__('EscalationPolicies|mins'),
  noRules: s__('EscalationPolicies|This policy has no escalation rules.'),
};

const isRuleValid = ({ status, elapsedTimeMinutes, oncallSchedule, user }) =>
  Object.keys(ALERT_STATUSES).includes(status) &&
  typeof elapsedTimeMinutes === 'number' &&
  (typeof oncallSchedule?.name === 'string' || typeof user?.username === 'string');

export default {
  i18n,
  ACTIONS,
  ALERT_STATUSES,
  EMAIL_ONCALL_SCHEDULE_USER,
  components: {
    GlButton,
    GlButtonGroup,
    GlCard,
    GlSprintf,
    GlIcon,
    GlCollapse,
    GlToken,
    GlAvatar,
    DeleteEscalationPolicyModal,
    EditEscalationPolicyModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    policy: {
      type: Object,
      required: true,
      validator: ({ name, rules }) => {
        return typeof name === 'string' && Array.isArray(rules) && rules.every(isRuleValid);
      },
    },
    index: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      isPolicyVisible: this.index === 0,
      bodyClass: '',
    };
  },
  computed: {
    policyVisibleChevronIcon() {
      return this.isPolicyVisible ? 'chevron-lg-down' : 'chevron-lg-right';
    },
    policyVisibleChevronIconLabel() {
      return this.isPolicyVisible ? __('Collapse') : __('Expand');
    },
    editPolicyModalId() {
      return `${editEscalationPolicyModalId}-${this.policy.id}`;
    },
    deletePolicyModalId() {
      return `${deleteEscalationPolicyModalId}-${this.policy.id}`;
    },
    mappedParticipants() {
      return getParticipantsWithTokenStyles(this.policy.rules);
    },
  },
  methods: {
    hasEscalationSchedule(rule) {
      return rule.oncallSchedule?.iid;
    },
    hasEscalationUser(rule) {
      return rule.user?.username;
    },
    getBackgroundStyle(rule) {
      const userIndex = getEscalationUserIndex(this.mappedParticipants, rule.user.username);
      return this.mappedParticipants[userIndex].style;
    },
    getTextClass(rule) {
      const userIndex = getEscalationUserIndex(this.mappedParticipants, rule.user.username);
      return this.mappedParticipants[userIndex].class;
    },
    getActionName(rule) {
      return (this.hasEscalationSchedule(rule)
        ? ACTIONS[EMAIL_ONCALL_SCHEDULE_USER]
        : ACTIONS[EMAIL_USER]
      ).toLowerCase();
    },
    getArrowLength(index) {
      // each next rule arrow's length will be +4% of the container width
      // the first arrow's length is 4% and the 10th is 40%
      const length = (index + 1) * 4;
      return `${length}%`;
    },
    getActionTooltip(rule) {
      return sprintf(i18n.escalationRuleAction, {
        notificationIcon: '',
        doAction: this.getActionName(rule),
        forScheduleOrUser: this.hasEscalationSchedule(rule)
          ? rule.oncallSchedule.name
          : rule.user.name,
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-card
      class="gl-mt-5"
      :class="{ 'gl-border-bottom-0': !isPolicyVisible }"
      :body-class="bodyClass"
      :header-class="{ 'gl-py-3': true, 'gl-rounded-base': !isPolicyVisible }"
    >
      <template #header>
        <div class="gl-display-flex gl-align-items-center">
          <gl-button
            v-gl-tooltip
            class="gl-mr-2 gl-p-0!"
            :title="policyVisibleChevronIconLabel"
            :aria-label="policyVisibleChevronIconLabel"
            category="tertiary"
            @click="isPolicyVisible = !isPolicyVisible"
          >
            <gl-icon :size="12" :name="policyVisibleChevronIcon" />
          </gl-button>

          <h3 class="gl-font-weight-bold gl-font-lg gl-m-0">{{ policy.name }}</h3>
          <gl-button-group class="gl-ml-auto">
            <gl-button
              v-gl-modal="editPolicyModalId"
              v-gl-tooltip
              :title="$options.i18n.editPolicy"
              icon="pencil"
              :aria-label="$options.i18n.editPolicy"
            />
            <gl-button
              v-gl-modal="deletePolicyModalId"
              v-gl-tooltip
              :title="$options.i18n.deletePolicy"
              :aria-label="$options.i18n.deletePolicy"
              icon="remove"
            />
          </gl-button-group>
        </div>
      </template>
      <gl-collapse
        :visible="isPolicyVisible"
        @hidden="bodyClass = 'gl-p-0'"
        @show="bodyClass = 'gl-p-5'"
      >
        <p v-if="policy.description" class="gl-text-gray-500 gl-mb-5">
          {{ policy.description }}
        </p>
        <div class="gl-border-solid gl-border-1 gl-border-gray-100 gl-rounded-base gl-p-5">
          <div v-if="!policy.rules.length" class="gl-text-red-500">
            <gl-icon name="status_warning" class="gl-mr-3" /> {{ $options.i18n.noRules }}
          </div>
          <template v-else>
            <div
              v-for="(rule, ruleIndex) in policy.rules"
              :key="rule.id"
              :class="{ 'gl-mb-5': ruleIndex !== policy.rules.length - 1 }"
              class="gl-display-flex gl-align-items-center escalation-rule-row"
            >
              <span class="rule-condition gl-md-w-full">
                <gl-sprintf :message="$options.i18n.escalationRuleCondition">
                  <template #clockIcon>
                    <gl-icon name="clock" class="gl-mr-3" />
                  </template>
                  <template #alertStatus>
                    {{ $options.ALERT_STATUSES[rule.status].toLowerCase() }}
                  </template>
                  <template #minutes>
                    <span class="gl-font-weight-bold">
                      {{ rule.elapsedTimeMinutes }}&nbsp;{{ $options.i18n.minutes }}
                    </span>
                  </template>
                </gl-sprintf>
              </span>

              <span
                class="right-arrow gl-relative gl-min-w-7 gl-bg-gray-900 gl-display-none gl-lg-display-block gl-flex-shrink-0 gl-mx-5"
                :style="{ width: getArrowLength(ruleIndex) }"
              >
                <i class="right-arrow-head gl-absolute gl-p-1 gl-border-solid"></i>
              </span>

              <span class="gl-display-flex gl-align-items-center gl-min-w-0">
                <span v-gl-tooltip class="gl-text-truncate" :title="getActionTooltip(rule)">
                  <gl-sprintf :message="$options.i18n.escalationRuleAction">
                    <template #notificationIcon>
                      <gl-icon name="notifications" class="gl-mr-3" />
                    </template>
                    <template #doAction>
                      {{ getActionName(rule) }}
                    </template>
                    <template #forScheduleOrUser>
                      <span v-if="hasEscalationSchedule(rule)" class="gl-font-weight-bold">
                        {{ rule.oncallSchedule.name }}
                      </span>
                      <gl-token
                        v-else-if="hasEscalationUser(rule)"
                        view-only
                        :style="getBackgroundStyle(rule)"
                        :class="getTextClass(rule)"
                      >
                        <gl-avatar :src="rule.user.avatarUrl" :size="16" />
                        {{ rule.user.name }}
                      </gl-token>
                    </template>
                  </gl-sprintf>
                </span>
              </span>
            </div>
          </template>
        </div>
      </gl-collapse>
    </gl-card>

    <delete-escalation-policy-modal :escalation-policy="policy" :modal-id="deletePolicyModalId" />
    <edit-escalation-policy-modal
      :escalation-policy="policy"
      :modal-id="editPolicyModalId"
      is-edit-mode
    />
  </div>
</template>
