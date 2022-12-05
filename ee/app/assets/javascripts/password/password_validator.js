import Vue from 'vue';
import PasswordRequirementList from 'ee/password/components/password_requirement_list.vue';

const initPasswordValidator = ({ allowNoPassword = false } = {}) => {
  const passwordInputSelector = '.js-password-complexity-validation';
  const passwordInputElement = document.querySelector(passwordInputSelector);
  const el = document.querySelector('#js-password-requirements-list');

  if (!passwordInputElement || !el) {
    return;
  }
  const ruleTypes = JSON.parse(el.dataset.ruleTypes);

  if (ruleTypes.length === 0) {
    return;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'PasswordRequirementListRoot',
    render(createElement) {
      return createElement(PasswordRequirementList, {
        props: {
          ruleTypes,
          allowNoPassword,
          passwordInputElement,
        },
      });
    },
  });
};

export default initPasswordValidator;
