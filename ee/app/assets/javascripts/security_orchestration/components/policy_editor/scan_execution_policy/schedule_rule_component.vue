<script>
import { GlButton, GlFormInput, GlSprintf, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import { slugify } from '~/lib/utils/text_utility';
import {
  DAYS,
  HOUR_MINUTE_LIST,
  CRONE_DEFAULT_TIME,
  CRONE_DEFAULT_DAY,
  setCroneTime,
  parseCroneTime,
  isCronDaily,
} from './lib';
import {
  DEFAULT_AGENT_NAME,
  SCAN_EXECUTION_RULES_LABELS,
  SCAN_EXECUTION_RULE_SCOPE_TYPE,
  SCAN_EXECUTION_RULE_PERIOD_TYPE,
} from './constants';

export default {
  SCAN_EXECUTION_RULES_LABELS,
  SCAN_EXECUTION_RULE_SCOPE_TYPE,
  SCAN_EXECUTION_RULE_PERIOD_TYPE,
  HOUR_MINUTE_LIST,
  DAYS,
  i18n: {
    scanResultExecutionCopy: s__(
      'ScanExecutionPolicy|%{ifLabelStart}if%{ifLabelEnd} %{rules} actions for the %{scopes} %{branches} %{namespaceLabel}',
    ),
    scanResultExecutionPeriod: s__('ScanExecutionPolicy|%{period} %{days} at %{time}'),
    selectedBranchesPlaceholder: s__('ScanExecutionPolicy|Select branches'),
    selectedAgentsPlaceholder: s__('ScanExecutionPolicy|Select agents'),
    selectedNamespacesPlaceholder: s__('ScanExecutionPolicy|Select namespaces'),
    namespaceLabel: s__('ScanExecutionPolicy|in namespaces'),
  },
  name: 'ScheduleRuleComponent',
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlFormInput,
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
      selectedRule: this.$options.SCAN_EXECUTION_RULES_LABELS.schedule,
      selectedTime: parseCroneTime(this.initRule.cadence).time,
      selectedDay: parseCroneTime(this.initRule.cadence).day,
      selectedDayIndex: 0,
      selectedTimeIndex: 0,
      croneString: this.initRule.cadence,
      agent: Object.keys(this.initRule.agents || {})[0] || DEFAULT_AGENT_NAME,
      selectedScope:
        'agents' in this.initRule
          ? this.$options.SCAN_EXECUTION_RULE_SCOPE_TYPE.cluster
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
    agentToAdd: {
      get() {
        return this.agent;
      },
      set(values) {
        this.agent = slugify(values, '');
        this.triggerChanged({
          agents: {
            [this.agent]: {
              namespaces: this.nameSpacesToAdd || [],
            },
          },
        });
      },
    },
    branchedToAdd: {
      get() {
        return (this.initRule.branches?.length || 0) === 0
          ? ''
          : this.initRule.branches?.filter((element) => element?.trim()).join(',');
      },
      set(values) {
        const branches = slugify(values, ',').split(',').filter(Boolean);
        this.triggerChanged({
          branches,
        });
      },
    },
    nameSpacesToAdd: {
      get() {
        return (this.initRule.agents?.[this.agent]?.namespaces || []).join(',') || '';
      },
      set(values) {
        const namespaces = slugify(values, ',').split(',').filter(Boolean);
        this.triggerChanged({
          agents: {
            [this.agent]: {
              namespaces,
            },
          },
        });
      },
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
    triggerChangedScope(value) {
      this.$emit('changed', { type: this.initRule.type, ...value, cadence: this.initRule.cadence });
    },
    isSelectedRule(key) {
      return this.selectedRule === this.$options.SCAN_EXECUTION_RULES_LABELS[key];
    },
    isScopeSelected(key) {
      return this.selectedScope === this.$options.SCAN_EXECUTION_RULE_SCOPE_TYPE[key];
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
    resetTime() {
      this.selectedTimeIndex = 0;
      this.selectedTime = HOUR_MINUTE_LIST[this.selectedTimeIndex];
      this.selectedDayIndex = 0;
      this.selectedDay = DAYS[this.selectedDayIndex];
    },
    resetScope() {
      this.nameSpacesToAdd = '';
      this.agent = Object.keys(this.initRule.agents || {})[0] || DEFAULT_AGENT_NAME;
    },
    setSelectedRule(key) {
      this.selectedRule = this.$options.SCAN_EXECUTION_RULES_LABELS[key];
      this.$emit('select-rule', key);
    },
    setPeriodSelected(key) {
      this.selectedPeriod = this.$options.SCAN_EXECUTION_RULE_PERIOD_TYPE[key];
      this.croneString = this.isCronDaily ? CRONE_DEFAULT_TIME : CRONE_DEFAULT_DAY;
      this.resetTime();
      this.triggerChanged({ cadence: this.croneString });
    },
    setTimeSelected(key) {
      this.selectedTime = HOUR_MINUTE_LIST[key];
      this.selectedTimeIndex = key;
      this.setCroneString({ time: key, day: this.selectedDayIndex });
    },
    setDaySelected(key) {
      this.selectedDay = DAYS[key];
      this.selectedDayIndex = key;
      this.setCroneString({ time: this.selectedTimeIndex, day: key });
    },
    setCroneString({ day, time }) {
      this.croneString = setCroneTime({ time, day });
      this.triggerChanged({ cadence: this.croneString });
    },
    setScopeSelected(key) {
      this.selectedScope = this.$options.SCAN_EXECUTION_RULE_SCOPE_TYPE[key];
      this.resetScope();
      const payload = this.isBranchScope
        ? { branches: [] }
        : { agents: { [DEFAULT_AGENT_NAME]: { namespaces: [] } } };
      this.triggerChangedScope(payload);
    },
  },
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-rounded-base px-3 pt-3 gl-relative gl-pb-4">
    <div class="gl-w-full gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap">
      <gl-sprintf :message="$options.i18n.scanResultExecutionCopy">
        <template #ifLabel>
          <label
            for="scanners"
            class="text-uppercase gl-font-lg gl-w-6"
            data-testid="rule-component-label"
            >{{ ruleLabel }}</label
          >
        </template>

        <template #scopes>
          <gl-dropdown :text="selectedScope" data-testid="rule-component-scope">
            <gl-dropdown-item
              v-for="(label, key) in $options.SCAN_EXECUTION_RULE_SCOPE_TYPE"
              :key="key"
              is-check-item
              :is-checked="isScopeSelected(key)"
              @click="setScopeSelected(key)"
            >
              {{ label }}
            </gl-dropdown-item>
          </gl-dropdown>
        </template>

        <template #rules>
          <gl-dropdown :text="selectedRule" data-testid="rule-component-type">
            <gl-dropdown-item
              v-for="(label, key) in $options.SCAN_EXECUTION_RULES_LABELS"
              :key="key"
              is-check-item
              :is-checked="isSelectedRule(key)"
              @click="setSelectedRule(key)"
            >
              {{ label }}
            </gl-dropdown-item>
          </gl-dropdown>
        </template>

        <template #branches>
          <gl-form-input
            v-if="isBranchScope"
            v-model="branchedToAdd"
            class="gl-mr-3 gl-max-w-34"
            :placeholder="$options.i18n.selectedBranchesPlaceholder"
            data-testid="pipeline-rule-branches"
          />
          <gl-form-input
            v-else
            v-model="agentToAdd"
            class="gl-max-w-34"
            :placeholder="$options.i18n.selectedAgentsPlaceholder"
            data-testid="pipeline-rule-agent"
          />
        </template>

        <template #namespaceLabel>
          <template v-if="!isBranchScope">{{ $options.i18n.namespaceLabel }}</template>

          <gl-form-input
            v-if="!isBranchScope"
            v-model="nameSpacesToAdd"
            class="gl-ml-7 gl-max-w-34"
            :placeholder="$options.i18n.selectedNamespacesPlaceholder"
            data-testid="pipeline-rule-namespaces"
          />
        </template>
      </gl-sprintf>
    </div>

    <div
      class="gl-w-full gl-mt-3 gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap gl-ml-7"
    >
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
    <gl-button
      icon="remove"
      category="tertiary"
      class="gl-absolute gl-top-1 gl-right-1"
      :aria-label="__('Remove')"
      data-testid="remove-rule"
      @click="$emit('remove')"
    />
  </div>
</template>
