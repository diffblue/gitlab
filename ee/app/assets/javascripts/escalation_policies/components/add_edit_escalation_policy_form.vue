<script>
import { GlLink, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { cloneDeep, uniqueId } from 'lodash';
import createFlash from '~/flash';
import { s__, __ } from '~/locale';
import { DEFAULT_ACTION, DEFAULT_ESCALATION_RULE, MAX_RULES_LENGTH } from '../constants';
import getOncallSchedulesQuery from '../graphql/queries/get_oncall_schedules.query.graphql';
import EscalationRule from './escalation_rule.vue';

export const i18n = {
  fields: {
    name: {
      title: __('Name'),
      validation: {
        empty: __("Can't be empty"),
      },
    },
    description: { title: __('Description (optional)') },
    rules: {
      title: s__('EscalationPolicies|Escalation rules'),
    },
  },
  addRule: s__('EscalationPolicies|+ Add an additional rule'),
  maxRules: s__('EscalationPolicies|Maximum of 10 rules has been reached.'),
  failedLoadingSchedules: s__('EscalationPolicies|Failed to load oncall-schedules'),
};

export default {
  i18n,
  components: {
    GlLink,
    GlForm,
    GlFormGroup,
    GlFormInput,
    EscalationRule,
  },
  inject: ['projectPath'],
  props: {
    form: {
      type: Object,
      required: true,
    },
    validationState: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      schedules: [],
      rules: [],
    };
  },
  apollo: {
    schedules: {
      query: getOncallSchedulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        const nodes = data.project?.incidentManagementOncallSchedules?.nodes ?? [];
        return nodes;
      },
      error(error) {
        createFlash({ message: i18n.failedLoadingSchedules, captureError: true, error });
      },
    },
  },
  computed: {
    schedulesLoading() {
      return this.$apollo.queries.schedules.loading;
    },
    hasMaxRules() {
      return this.rules?.length === MAX_RULES_LENGTH;
    },
  },
  mounted() {
    this.rules = this.form.rules.map((rule) => {
      const {
        status,
        elapsedTimeMinutes,
        oncallSchedule: { iid: oncallScheduleIid },
      } = rule;

      return {
        status,
        elapsedTimeMinutes,
        action: DEFAULT_ACTION,
        oncallScheduleIid,
        key: uniqueId(),
      };
    });

    if (!this.rules.length) {
      this.addRule();
    }
  },
  methods: {
    addRule() {
      this.rules.push({ ...cloneDeep(DEFAULT_ESCALATION_RULE), key: uniqueId() });
    },
    updateEscalationRules({ rule, index }) {
      this.rules[index] = { ...this.rules[index], ...rule };
      this.emitRulesUpdate();
    },
    removeEscalationRule(index) {
      this.rules.splice(index, 1);
      this.emitRulesUpdate();
    },
    emitRulesUpdate() {
      this.$emit('update-escalation-policy-form', { field: 'rules', value: this.rules });
    },
  },
};
</script>

<template>
  <gl-form>
    <div class="w-75 gl-xs-w-full!">
      <gl-form-group
        data-testid="escalation-policy-name"
        :label="$options.i18n.fields.name.title"
        :invalid-feedback="$options.i18n.fields.name.validation.empty"
        label-size="sm"
        label-for="escalation-policy-name"
        :state="validationState.name"
        required
      >
        <gl-form-input
          id="escalation-policy-name"
          :value="form.name"
          @blur="
            $emit('update-escalation-policy-form', { field: 'name', value: $event.target.value })
          "
        />
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.fields.description.title"
        label-size="sm"
        label-for="escalation-policy-description"
      >
        <gl-form-input
          id="escalation-policy-description"
          :value="form.description"
          @blur="
            $emit('update-escalation-policy-form', {
              field: 'description',
              value: $event.target.value,
            })
          "
        />
      </gl-form-group>
    </div>

    <gl-form-group class="gl-mb-3" :label="$options.i18n.fields.rules.title" label-size="sm">
      <escalation-rule
        v-for="(rule, index) in rules"
        :key="rule.key"
        :rule="rule"
        :index="index"
        :schedules="schedules"
        :schedules-loading="schedulesLoading"
        :validation-state="validationState.rules[index]"
        @update-escalation-rule="updateEscalationRules"
        @remove-escalation-rule="removeEscalationRule"
      />
    </gl-form-group>
    <gl-link v-if="!hasMaxRules" @click="addRule">
      <span>{{ $options.i18n.addRule }}</span>
    </gl-link>
    <span v-else data-testid="max-rules-text" class="gl-text-gray-500">
      {{ $options.i18n.maxRules }}
    </span>
  </gl-form>
</template>
