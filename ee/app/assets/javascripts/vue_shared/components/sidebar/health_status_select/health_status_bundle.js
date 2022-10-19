import Vue from 'vue';
import HealthStatusDropdown from 'ee/sidebar/components/health_status/health_status_dropdown.vue';
import { healthStatusForRestApi } from 'ee/sidebar/constants';

export default () => {
  const el = document.getElementById('js-bulk-update-health-status-root');
  const healthStatusFormInput = document.getElementById('issue_health_status_value');

  if (!el || !healthStatusFormInput) {
    return null;
  }

  return new Vue({
    el,
    name: 'HealthStatusSelectRoot',
    data() {
      return {
        healthStatus: undefined,
      };
    },
    methods: {
      handleHealthStatusSelect(healthStatus) {
        this.healthStatus = healthStatus;
        healthStatusFormInput.setAttribute(
          'value',
          healthStatusForRestApi[healthStatus || 'NO_STATUS'],
        );
      },
    },
    render(createElement) {
      return createElement(HealthStatusDropdown, {
        props: {
          healthStatus: this.healthStatus,
        },
        on: {
          change: this.handleHealthStatusSelect.bind(this),
        },
      });
    },
  });
};
