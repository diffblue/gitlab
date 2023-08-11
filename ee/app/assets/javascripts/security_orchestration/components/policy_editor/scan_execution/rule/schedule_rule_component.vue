<script>
import {
  GlFormInput,
  GlSprintf,
  GlCollapsibleListbox,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import { slugify, slugifyToArray } from '../../utils';
import {
  DAYS,
  HOUR_MINUTE_LIST,
  CRON_DEFAULT_TIME,
  CRON_DEFAULT_DAY,
  setCronTime,
  parseCronTime,
  isCronDaily,
} from '../lib';
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
} from '../constants';
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
    schedulePeriod: s__(
      'ScanExecutionPolicy|%{period} %{days} at %{time} %{timezoneLabel} %{timezone}',
    ),
    selectedAgentsPlaceholder: s__('ScanExecutionPolicy|Select agent'),
    selectedNamespacesPlaceholder: s__('ScanExecutionPolicy|Select namespaces'),
    namespaceLabel: s__('ScanExecutionPolicy|in namespaces'),
    branchTimezoneHeader: s__('ScanExecutionPolicy|Select timezone'),
    kubernetesTimezoneHeader: s__("ScanExecutionPolicy|Kubernetes agent's timezone"),
    kubernetesTimezoneLabel: s__('ScanExecutionPolicy|on the Kubernetes agent pod'),
    branchTimezoneLabel: s__('ScanExecutionPolicy|on %{hostname}'),
    agentTimezoneTooltipText: s__("ScanExecutionPolicy|Kubernetes agent's timezone"),
    branchTimezoneTooltipText: s__("ScanExecutionPolicy|%{hostname}'s timezone"),
  },
  name: 'ScheduleRuleComponent',
  components: {
    BaseRuleComponent,
    GlFormInput,
    GlCollapsibleListbox,
    GlSprintf,
    TimezoneDropdown,
  },
  directives: {
    GlTooltip,
  },
  inject: ['timezones'],
  props: {
    initRule: {
      type: Object,
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
    getHostname() {
      return window?.location?.host;
    },
    isBranchScope() {
      return this.selectedScope === SCAN_EXECUTION_RULE_SCOPE_BRANCH_KEY;
    },
    isCronDaily() {
      return this.selectedPeriod === SCAN_EXECUTION_RULE_PERIOD_DAILY_KEY;
    },
    nameSpacesToAdd() {
      return (this.initRule.agents?.[this.agent]?.namespaces || []).join(',') || '';
    },
    timezone() {
      return this.initRule.timezone || '';
    },
    selectedScopeText() {
      return SCAN_EXECUTION_RULE_SCOPE_TYPE[this.selectedScope];
    },
    selectedPeriodText() {
      return SCAN_EXECUTION_RULE_PERIOD_TYPE[this.selectedPeriod];
    },
    timezoneHeader() {
      return this.isBranchScope
        ? this.$options.i18n.branchTimezoneHeader
        : this.$options.i18n.kubernetesTimezoneHeader;
    },
    timezoneLabel() {
      return this.isBranchScope
        ? sprintf(this.$options.i18n.branchTimezoneLabel, {
            hostname: this.getHostname,
          })
        : this.$options.i18n.kubernetesTimezoneLabel;
    },
    timezoneTooltipText() {
      return this.isBranchScope
        ? sprintf(this.$options.i18n.branchTimezoneTooltipText, {
            hostname: this.getHostname,
          })
        : this.$options.i18n.agentTimezoneTooltipText;
    },
  },
  methods: {
    convertToListboxItems(items) {
      return Object.entries(items).map(([value, text]) => ({ value, text }));
    },
    handleTimeZoneInput({ identifier }) {
      this.triggerChanged({ timezone: identifier });
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

    <template #period>
      <span class="gl-display-flex gl-align-items-center gl-flex-wrap gl-gap-3">
        <gl-sprintf :message="$options.i18n.schedulePeriod">
          <template #period>
            <gl-collapsible-listbox
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
              :items="convertToListboxItems($options.DAYS)"
              :selected="selectedDayIndex"
              :toggle-text="selectedDay"
              @select="setDaySelected"
            />
          </template>

          <template #time>
            <gl-collapsible-listbox
              data-testid="rule-component-time"
              :items="convertToListboxItems($options.HOUR_MINUTE_LIST)"
              :toggle-text="selectedTime"
              :selected="selectedTimeIndex"
              @select="setTimeSelected"
            />
          </template>

          <template #timezoneLabel>
            <span data-testid="timezone-label">{{ timezoneLabel }}</span>
          </template>

          <template #timezone>
            <timezone-dropdown
              v-gl-tooltip.right.viewport
              class="gl-max-w-26"
              :header-text="timezoneHeader"
              :value="timezone"
              :timezone-data="timezones"
              :title="timezoneTooltipText"
              @input="handleTimeZoneInput"
            />
          </template>
        </gl-sprintf>
      </span>
    </template>
  </base-rule-component>
</template>
