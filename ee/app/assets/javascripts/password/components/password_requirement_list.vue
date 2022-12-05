<script>
import { GlIcon } from '@gitlab/ui';
import {
  INVALID_FORM_CLASS,
  INVALID_INPUT_CLASS,
  PASSWORD_REQUIREMENTS_ID,
  PASSWORD_RULE_MAP,
  RED_TEXT_CLASS,
  GREEN_TEXT_CLASS,
  HIDDEN_ELEMENT_CLASS,
  I18N,
} from '../constants';

export default {
  components: {
    GlIcon,
  },
  props: {
    allowNoPassword: {
      type: Boolean,
      required: true,
    },
    passwordInputElement: {
      type: Element,
      required: true,
    },
    ruleTypes: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      password: '',
      submitted: false,
      ruleList: this.ruleTypes.map((type) => {
        return PASSWORD_RULE_MAP[type];
      }),
    };
  },
  computed: {
    failRequirements() {
      const satisfyRules = this.ruleList.every((rule) => this.checkValidity(rule.reg));

      return !satisfyRules && !this.isEmptyPasswordLegal;
    },
    isEmptyPasswordLegal() {
      return this.password.trim() === '' && this.allowNoPassword;
    },
  },
  mounted() {
    const formElement = this.passwordInputElement.form;

    this.passwordInputElement.setAttribute('aria-describedby', PASSWORD_REQUIREMENTS_ID);
    this.passwordInputElement.addEventListener('input', () => {
      this.password = this.passwordInputElement.value;
      if (this.failRequirements && this.submitted) {
        this.passwordInputElement.classList.add(INVALID_INPUT_CLASS);
      } else {
        this.passwordInputElement.classList.remove(INVALID_INPUT_CLASS);
      }
    });

    formElement.querySelector('[type="submit"]').addEventListener('click', () => {
      this.submitted = true;
      if (this.failRequirements) {
        this.passwordInputElement.focus();
        this.passwordInputElement.classList.add(INVALID_INPUT_CLASS);
        formElement.classList.add(INVALID_FORM_CLASS);
      }
    });

    formElement.addEventListener('submit', (e) => {
      if (this.failRequirements) {
        e.preventDefault();
        e.stopPropagation();
      }
    });
  },
  methods: {
    checkValidity(reg) {
      return reg.test(this.password);
    },
    getAriaLabel(reg) {
      if (this.checkValidity(reg)) {
        return I18N.PASSWORD_SATISFIED;
      } else if (this.submitted) {
        return I18N.PASSWORD_NOT_SATISFIED;
      }
      return I18N.PASSWORD_TO_BE_SATISFIED;
    },
    calculateTextClass(reg) {
      return {
        [this.$options.RED_TEXT_CLASS]: this.submitted && !this.checkValidity(reg),
        [this.$options.GREEN_TEXT_CLASS]: this.checkValidity(reg),
      };
    },
  },
  RED_TEXT_CLASS,
  GREEN_TEXT_CLASS,
  HIDDEN_ELEMENT_CLASS,
};
</script>

<template>
  <div v-show="!isEmptyPasswordLegal" data-testid="password-requirement-list">
    <div
      v-for="(rule, index) in ruleList"
      :key="rule.text"
      class="gl-line-height-28 gl-display-flex gl-align-items-center"
      aria-live="polite"
    >
      <span
        :class="{ [$options.HIDDEN_ELEMENT_CLASS]: !checkValidity(rule.reg) }"
        :data-testid="`password-${ruleTypes[index]}-status-icon`"
        class="gl-display-flex gl-align-items-center gl-mr-2 password-status-icon password-status-icon-success"
        :aria-label="getAriaLabel(rule.reg)"
      >
        <gl-icon name="check" :size="16" />
      </span>
      <span data-testid="password-rule-text" :class="calculateTextClass(rule.reg)">{{
        rule.text
      }}</span>
    </div>
  </div>
</template>
