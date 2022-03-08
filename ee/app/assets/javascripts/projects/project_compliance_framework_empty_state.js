import Vue from 'vue';
import ProjectComplianceFrameworkEmptyState from './components/project_compliance_framework_empty_state.vue';

export default (selector = '#js-project-compliance-framework-empty-state') => {
  const el = document.querySelector(selector);

  if (!el) return;

  const { groupName, groupPath, addFrameworkPath, emptyStateSvgPath } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(createElement) {
      return createElement(ProjectComplianceFrameworkEmptyState, {
        props: {
          groupName,
          groupPath,
          addFrameworkPath,
          emptyStateSvgPath,
        },
      });
    },
  });
};
