<script>
import { GlFormInput, GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
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
  SCAN_EXECUTION_RULE_SCOPE_TYPE,
  SCAN_EXECUTION_RULE_SCOPE_BRANCH_KEY,
  SCAN_EXECUTION_RULE_SCOPE_AGENT_KEY,
  SCAN_EXECUTION_RULE_PERIOD_TYPE,
  SCAN_EXECUTION_RULES_SCHEDULE_KEY,
  SCAN_EXECUTION_RULE_PERIOD_DAILY_KEY,
  SCAN_EXECUTION_RULE_PERIOD_WEEKLY_KEY,
} from './constants';
import BaseRuleComponent from './base_rule_component.vue';

export default {
  SCAN_EXECUTION_RULE_SCOPE_TYPE,
  SCAN_EXECUTION_RULE_PERIOD_TYPE,
  SCAN_EXECUTION_RULES_SCHEDULE_KEY,
  SCAN_EXECUTION_RULE_PERIOD_DAILY_KEY,
  SCAN_EXECUTION_RULE_PERIOD_WEEKLY_KEY,
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
    GlCollapsibleListbox,
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
      selectedDayIndex: parseCronTime(this.initRule.cadence).dayIndex,
      selectedTimeIndex: parseCronTime(this.initRule.cadence).timeIndex,
      cronString: this.initRule.cadence,
      agent: Object.keys(this.initRule.agents || {})[0] || DEFAULT_AGENT_NAME,
      selectedScope:
        AGENT_KEY in this.initRule
          ? SCAN_EXECUTION_RULE_SCOPE_AGENT_KEY
          : SCAN_EXECUTION_RULE_SCOPE_BRANCH_KEY,
      selectedPeriod: isCronDaily(this.initRule.cadence)
        ? SCAN_EXECUTION_RULE_PERIOD_DAILY_KEY
        : SCAN_EXECUTION_RULE_PERIOD_WEEKLY_KEY,
    };
  },
  computed: {
    isBranchScope() {
      return this.selectedScope === SCAN_EXECUTION_RULE_SCOPE_BRANCH_KEY;
    },
    isCronDaily() {
      return this.selectedPeriod === SCAN_EXECUTION_RULE_PERIOD_DAILY_KEY;
    },
    nameSpacesToAdd() {
      return (this.initRule.agents?.[this.agent]?.namespaces || []).join(',') || '';
    },
    selectedScopeText() {
      return SCAN_EXECUTION_RULE_SCOPE_TYPE[this.selectedScope];
    },
    selectedPeriodText() {
      return SCAN_EXECUTION_RULE_PERIOD_TYPE[this.selectedPeriod];
    },
  },
  methods: {
    convertToListboxItems(items) {
      return Object.entries(items).map(([value, text]) => ({ value, text }));
    },
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
    triggerChangedScope(value) {
      this.$emit('changed', { type: this.initRule.type, ...value, cadence: this.initRule.cadence });
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
      this.selectedPeriod = key;
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
      this.selectedScope = key;
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
    :default-selected-rule="$options.SCAN_EXECUTION_RULES_SCHEDULE_KEY"
    :init-rule="initRule"
    :rule-label="ruleLabel"
    :is-branch-scope="isBranchScope"
    v-on="$listeners"
  >
    <template #scopes>
      <gl-collapsible-listbox
        data-testid="rule-component-scope"
        :items="convertToListboxItems($options.SCAN_EXECUTION_RULE_SCOPE_TYPE)"
        :selected="selectedScope"
        :toggle-text="selectedScopeText"
        @select="setScopeSelected"
      />
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
            <gl-collapsible-listbox
              class="gl-mr-3"
              data-testid="rule-component-period"
              :items="convertToListboxItems($options.SCAN_EXECUTION_RULE_PERIOD_TYPE)"
              :toggle-text="selectedPeriodText"
              :selected="selectedPeriod"
              @select="setPeriodSelected"
            />
          </template>

          <template #days>
            <gl-collapsible-listbox
              v-if="!isCronDaily"
              data-testid="rule-component-day"
              class="gl-ml-3 gl-mr-3"
              :items="convertToListboxItems($options.DAYS)"
              :selected="selectedDayIndex"
              :toggle-text="selectedDay"
              @select="setDaySelected"
            />
          </template>

          <template #time>
            <gl-collapsible-listbox
              class="gl-ml-3 gl-mr-3"
              data-testid="rule-component-time"
              :items="convertToListboxItems($options.HOUR_MINUTE_LIST)"
              :toggle-text="selectedTime"
              :selected="selectedTimeIndex"
              @select="setTimeSelected"
            />
          </template>
        </gl-sprintf>
      </div>
    </template>
  </base-rule-component>
</template>
