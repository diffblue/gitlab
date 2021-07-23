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
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import {
  ACTIONS,
  ALERT_STATUSES,
  DEFAULT_ACTION,
  deleteEscalationPolicyModalId,
  editEscalationPolicyModalId,
} from '../constants';
import EditEscalationPolicyModal from './add_edit_escalation_policy_modal.vue';
import DeleteEscalationPolicyModal from './delete_escalation_policy_modal.vue';

export const i18n = {
  editPolicy: s__('EscalationPolicies|Edit escalation policy'),
  deletePolicy: s__('EscalationPolicies|Delete escalation policy'),
  escalationRule: s__(
    'EscalationPolicies|IF alert is not %{alertStatus} in %{minutes} %{then} THEN %{doAction} %{schedule}',
  ),
  minutes: s__('EscalationPolicies|mins'),
  noRules: s__('EscalationPolicies|This policy has no escalation rules.'),
};

const isRuleValid = ({ status, elapsedTimeMinutes, oncallSchedule: { name } }) =>
  Object.keys(ALERT_STATUSES).includes(status) &&
  typeof elapsedTimeMinutes === 'number' &&
  typeof name === 'string';

export default {
  i18n,
  ACTIONS,
  ALERT_STATUSES,
  DEFAULT_ACTION,
  components: {
    GlButton,
    GlButtonGroup,
    GlCard,
    GlSprintf,
    GlIcon,
    GlCollapse,
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
    policyVisibleAngleIcon() {
      return this.isPolicyVisible ? 'angle-down' : 'angle-right';
    },
    policyVisibleAngleIconLabel() {
      return this.isPolicyVisible ? __('Collapse') : __('Expand');
    },
    editPolicyModalId() {
      return `${editEscalationPolicyModalId}-${this.policy.id}`;
    },
    deletePolicyModalId() {
      return `${deleteEscalationPolicyModalId}-${this.policy.id}`;
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
            :title="policyVisibleAngleIconLabel"
            :aria-label="policyVisibleAngleIconLabel"
            category="tertiary"
            @click="isPolicyVisible = !isPolicyVisible"
          >
            <gl-icon :size="12" :name="policyVisibleAngleIcon" />
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
            >
              <gl-icon name="clock" class="gl-mr-3" />
              <gl-sprintf :message="$options.i18n.escalationRule">
                <template #alertStatus>
                  {{ $options.ALERT_STATUSES[rule.status].toLowerCase() }}
                </template>
                <template #minutes>
                  <span class="gl-font-weight-bold">
                    {{ rule.elapsedTimeMinutes }} {{ $options.i18n.minutes }}
                  </span>
                </template>
                <template #then>
                  <span class="right-arrow">
                    <i class="right-arrow-head"></i>
                  </span>
                  <gl-icon name="notifications" class="gl-mr-3" />
                </template>
                <template #doAction>
                  {{ $options.ACTIONS[$options.DEFAULT_ACTION].toLowerCase() }}
                </template>
                <template #schedule>
                  <span class="gl-font-weight-bold">
                    {{ rule.oncallSchedule.name }}
                  </span>
                </template>
              </gl-sprintf>
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
