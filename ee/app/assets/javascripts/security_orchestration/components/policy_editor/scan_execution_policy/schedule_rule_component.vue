<script>
import { GlSprintf, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
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
    selectedBranchesPlaceholder: s__('ScanExecutionPolicy|Select branches'),
  },
  name: 'ScheduleRuleComponent',
  components: {
    BaseRuleComponent,
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
      selectedScope: this.$options.SCAN_EXECUTION_RULE_SCOPE_TYPE.branch,
      selectedPeriod: isCronDaily(this.initRule.cadence)
        ? this.$options.SCAN_EXECUTION_RULE_PERIOD_TYPE.daily
        : this.$options.SCAN_EXECUTION_RULE_PERIOD_TYPE.weekly,
    };
  },
  computed: {
    isCronDaily() {
      return this.selectedPeriod === this.$options.SCAN_EXECUTION_RULE_PERIOD_TYPE.daily;
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
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
  },
};
</script>

<template>
  <base-rule-component
    :default-selected-rule="$options.SCAN_EXECUTION_RULES_LABELS.schedule"
    :init-rule="initRule"
    :rule-label="ruleLabel"
    v-on="$listeners"
  >
    <template #scopes>
      <gl-dropdown :text="selectedScope" data-testid="rule-component-scope">
        <gl-dropdown-item
          v-for="(label, key) in $options.SCAN_EXECUTION_RULE_SCOPE_TYPE"
          :key="key"
          is-check-item
        >
          {{ label }}
        </gl-dropdown-item>
      </gl-dropdown>
    </template>

    <template #content>
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
    </template>
  </base-rule-component>
</template>
