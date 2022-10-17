<script>
import { GlFormInput, GlSprintf, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import { slugify, slugifyToArray } from '../utils';
import {
  DAYS,
  HOUR_MINUTE_LIST,
  CRON_DEFAULT_TIME,
  CRON_DEFAULT_DAY,
  setCronTime,
  parseCronTime,
  isCronDaily,
} from './lib';
import {
  AGENT_KEY,
  DEFAULT_AGENT_NAME,
  SCAN_EXECUTION_RULES_LABELS,
  SCAN_EXECUTION_RULE_SCOPE_TYPE,
  SCAN_EXECUTION_RULE_PERIOD_TYPE,
} from './constants';
import BaseRuleComponent from './base_rule_component.vue';

export default {
  SCAN_EXECUTION_RULES_LABELS,
  SCAN_EXECUTION_RULE_SCOPE_TYPE,
  SCAN_EXECUTION_RULE_PERIOD_TYPE,
  HOUR_MINUTE_LIST,
  DAYS,
  i18n: {
    scanResultExecutionPeriod: s__('ScanExecutionPolicy|%{period} %{days} at %{time}'),
    selectedAgentsPlaceholder: s__('ScanExecutionPolicy|Select agent'),
    selectedNamespacesPlaceholder: s__('ScanExecutionPolicy|Select namespaces'),
    namespaceLabel: s__('ScanExecutionPolicy|in namespaces'),
  },
  name: 'ScheduleRuleComponent',
  components: {
    BaseRuleComponent,
    GlFormInput,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
  },
  props: {
    initRule: {
      type: Object,
      required: true,
    },
    ruleLabel: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedTime: parseCronTime(this.initRule.cadence).time,
      selectedDay: parseCronTime(this.initRule.cadence).day,
      selectedDayIndex: 0,
      selectedTimeIndex: 0,
      cronString: this.initRule.cadence,
      agent: Object.keys(this.initRule.agents || {})[0] || DEFAULT_AGENT_NAME,
      selectedScope:
        AGENT_KEY in this.initRule
          ? this.$options.SCAN_EXECUTION_RULE_SCOPE_TYPE.agent
          : this.$options.SCAN_EXECUTION_RULE_SCOPE_TYPE.branch,
      selectedPeriod: isCronDaily(this.initRule.cadence)
        ? this.$options.SCAN_EXECUTION_RULE_PERIOD_TYPE.daily
        : this.$options.SCAN_EXECUTION_RULE_PERIOD_TYPE.weekly,
    };
  },
  computed: {
    isBranchScope() {
      return this.selectedScope === this.$options.SCAN_EXECUTION_RULE_SCOPE_TYPE.branch;
    },
    isCronDaily() {
      return this.selectedPeriod === this.$options.SCAN_EXECUTION_RULE_PERIOD_TYPE.daily;
    },
    nameSpacesToAdd() {
      return (this.initRule.agents?.[this.agent]?.namespaces || []).join(',') || '';
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
    triggerChangedScope(value) {
      this.$emit('changed', { type: this.initRule.type, ...value, cadence: this.initRule.cadence });
    },
    isPeriodSelected(key) {
      return this.selectedPeriod === this.$options.SCAN_EXECUTION_RULE_PERIOD_TYPE[key];
    },
    isTimeSelected(key) {
      return this.selectedTime === HOUR_MINUTE_LIST[key];
    },
    isDaySelected(key) {
      return this.selectedDay === DAYS[key];
    },
    resetScope() {
      this.updateNamespaces('');
      this.agent = Object.keys(this.initRule.agents || {})[0] || DEFAULT_AGENT_NAME;
    },
    resetTime() {
      this.selectedTimeIndex = 0;
      this.selectedTime = HOUR_MINUTE_LIST[this.selectedTimeIndex];
      this.selectedDayIndex = 0;
      this.selectedDay = DAYS[this.selectedDayIndex];
    },
    setPeriodSelected(key) {
      this.selectedPeriod = this.$options.SCAN_EXECUTION_RULE_PERIOD_TYPE[key];
      this.cronString = this.isCronDaily ? CRON_DEFAULT_TIME : CRON_DEFAULT_DAY;
      this.resetTime();
      this.triggerChanged({ cadence: this.cronString });
    },
    setTimeSelected(key) {
      this.selectedTime = HOUR_MINUTE_LIST[key];
      this.selectedTimeIndex = key;
      this.setCronString({ time: key, day: this.selectedDayIndex });
    },
    setDaySelected(key) {
      this.selectedDay = DAYS[key];
      this.selectedDayIndex = key;
      this.setCronString({ time: this.selectedTimeIndex, day: key });
    },
    setCronString({ day, time }) {
      this.cronString = setCronTime({ time, day });
      this.triggerChanged({ cadence: this.cronString });
    },
    setScopeSelected(key) {
      this.selectedScope = this.$options.SCAN_EXECUTION_RULE_SCOPE_TYPE[key];
      this.resetScope();
      const payload = this.isBranchScope
        ? { branches: [] }
        : { agents: { [DEFAULT_AGENT_NAME]: { namespaces: [] } } };
      this.triggerChangedScope(payload);
    },
    slugifyNamespaces(values) {
      return slugifyToArray(values, ',');
    },
    updateAgent(values) {
      this.agent = slugify(values, '') || DEFAULT_AGENT_NAME;

      this.triggerChanged({
        agents: {
          [this.agent]: {
            namespaces: this.slugifyNamespaces(this.nameSpacesToAdd) || [],
          },
        },
      });
    },
    updateNamespaces(values) {
      this.triggerChanged({
        agents: {
          [this.agent]: {
            namespaces: this.slugifyNamespaces(values),
          },
        },
      });
    },
  },
};
</script>

<template>
  <base-rule-component
    :default-selected-rule="$options.SCAN_EXECUTION_RULES_LABELS.schedule"
    :init-rule="initRule"
    :rule-label="ruleLabel"
    :is-branch-scope="isBranchScope"
    v-on="$listeners"
  >
    <template #scopes>
      <gl-dropdown :text="selectedScope" data-testid="rule-component-scope">
        <gl-dropdown-item
          v-for="(label, key) in $options.SCAN_EXECUTION_RULE_SCOPE_TYPE"
          :key="key"
          is-check-item
          @click="setScopeSelected(key)"
        >
          {{ label }}
        </gl-dropdown-item>
      </gl-dropdown>
    </template>

    <template #agents>
      <gl-form-input
        v-if="!isBranchScope"
        class="gl-max-w-34"
        :value="agent"
        :placeholder="$options.i18n.selectedAgentsPlaceholder"
        data-testid="pipeline-rule-agent"
        @update="updateAgent"
      />
    </template>

    <template #namespaces>
      <template v-if="!isBranchScope">
        <span>{{ $options.i18n.namespaceLabel }}</span>
      </template>

      <gl-form-input
        v-if="!isBranchScope"
        class="gl-max-w-34"
        :value="nameSpacesToAdd"
        :placeholder="$options.i18n.selectedNamespacesPlaceholder"
        data-testid="pipeline-rule-namespaces"
        @update="updateNamespaces"
      />
    </template>

    <template #content>
      <div class="gl-w-full gl-mt-3 gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap">
        <gl-sprintf :message="$options.i18n.scanResultExecutionPeriod">
          <template #period>
            <gl-dropdown class="gl-mr-3" :text="selectedPeriod" data-testid="rule-component-period">
              <gl-dropdown-item
                v-for="(label, key) in $options.SCAN_EXECUTION_RULE_PERIOD_TYPE"
                :key="key"
                is-check-item
                :is-checked="isPeriodSelected(key)"
                @click="setPeriodSelected(key)"
              >
                {{ label }}
              </gl-dropdown-item>
            </gl-dropdown>
          </template>

          <template #days>
            <gl-dropdown
              v-if="!isCronDaily"
              class="gl-mr-3"
              :text="selectedDay"
              data-testid="rule-component-day"
            >
              <gl-dropdown-item
                v-for="(label, key) in $options.DAYS"
                :key="key"
                is-check-item
                :is-checked="isDaySelected(key)"
                @click="setDaySelected(key)"
              >
                {{ label }}
              </gl-dropdown-item>
            </gl-dropdown>
          </template>

          <template #time>
            <gl-dropdown
              class="gl-ml-3 gl-mr-3"
              :text="selectedTime"
              data-testid="rule-component-time"
            >
              <gl-dropdown-item
                v-for="(label, key) in $options.HOUR_MINUTE_LIST"
                :key="key"
                is-check-item
                :is-checked="isTimeSelected(key)"
                @click="setTimeSelected(key)"
              >
                {{ label }}
              </gl-dropdown-item>
            </gl-dropdown>
          </template>
        </gl-sprintf>
      </div>
    </template>
  </base-rule-component>
</template>
