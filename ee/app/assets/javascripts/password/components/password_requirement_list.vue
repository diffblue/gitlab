<script>
import { GlSafeHtmlDirective, GlIcon } from '@gitlab/ui';
import { PASSWORD_RULE_MAP } from '../constants';

export default {
  components: {
    GlIcon,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    submitted: {
      type: Boolean,
      required: true,
    },
    password: {
      type: String,
      required: true,
    },
    ruleTypes: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      ruleList: this.ruleTypes.map((type) => {
        return PASSWORD_RULE_MAP[type];
      }),
    };
  },
  computed: {
    meetRequirements() {
      return this.ruleList.every((rule) => this.checkValidity(rule.reg));
    },
  },
  methods: {
    checkValidity(reg) {
      return reg.test(this.password);
    },
  },
};
</script>

<template>
  <div>
    <div
      v-for="(rule, index) in ruleList"
      :key="rule.text"
      class="gl-h-7 gl-display-flex gl-align-items-center"
      aria-live="polite"
    >
      <span
        :class="{ 'gl-visibility-hidden': !checkValidity(rule.reg) }"
        class="gl-display-flex gl-align-items-center gl-mr-2 password-status-icon password-status-icon-success"
        :data-testid="'password-' + ruleTypes[index] + '-status-icon'"
      >
        <gl-icon name="check-circle" :size="16" :aria-label="__('Satisfied')" />
      </span>
      <span
        :class="{ 'gl-text-red-500': submitted && !checkValidity(rule.reg) }"
        data-testid="password-rule-text"
        >{{ rule.text }}</span
      >
    </div>
  </div>
</template>
