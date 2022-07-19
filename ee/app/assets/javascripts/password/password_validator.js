import Vue from 'vue';
import InputValidator from '~/validators/input_validator';
import PasswordRequirementList from 'ee/password/components/password_requirement_list.vue';

const invalidInputClass = 'gl-field-error-outline';
const passwordRequirementsId = 'password-requirements';

export default class PasswordValidator extends InputValidator {
  constructor(opts = {}) {
    super();
    const container = opts.container || '';
    const passwordInputBox = document.querySelector(
      `${container} .js-password-complexity-validation`,
    );
    const el = document.querySelector('#js-password-requirements-list');

    if (!passwordInputBox || !el) {
      return;
    }
    const ruleTypes = JSON.parse(el.dataset.ruleTypes);

    if (ruleTypes.length === 0) {
      return;
    }

    passwordInputBox.setAttribute('aria-describedby', passwordRequirementsId);

    // eslint-disable-next-line no-new
    new Vue({
      el,
      name: 'PasswordRequirementListRoot',
      data() {
        return {
          ruleTypes,
          password: '',
          submitted: false,
        };
      },
      mounted() {
        passwordInputBox.addEventListener('input', () => {
          this.password = passwordInputBox.value;
        });

        const submitButtonElement = passwordInputBox.form.querySelector('input[type="submit"]');
        submitButtonElement.addEventListener('click', () => {
          const { passwordRequirementList } = this.$refs;
          this.submitted = true;
          if (!passwordRequirementList.meetRequirements) {
            passwordInputBox.focus();
            passwordInputBox.classList.add(invalidInputClass);
          }
        });

        passwordInputBox.form.addEventListener('submit', (e) => {
          const { passwordRequirementList } = this.$refs;
          if (!passwordRequirementList.meetRequirements) {
            e.preventDefault();
            e.stopPropagation();
          }
        });
      },
      render(createElement) {
        return createElement(PasswordRequirementList, {
          ref: 'passwordRequirementList',
          props: {
            password: this.password,
            submitted: this.submitted,
            ruleTypes: this.ruleTypes,
          },
        });
      },
    });
  }
}
