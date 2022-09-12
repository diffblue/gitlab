import '~/pages/admin/application_settings/ci_cd/index';
import Vue from 'vue';
import CiTemplateDropdown from './ci_template_dropdown.vue';

const el = document.querySelector('.js-ci-template-dropdown');
const { gitlabCiYmls, value } = el.dataset;

// eslint-disable-next-line no-new
new Vue({
  el,
  provide: {
    gitlabCiYmls: JSON.parse(gitlabCiYmls),
    initialSelectedGitlabCiYmlName: value,
  },
  render(createElement) {
    return createElement(CiTemplateDropdown);
  },
});
