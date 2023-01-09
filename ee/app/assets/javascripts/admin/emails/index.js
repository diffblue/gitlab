import Vue from 'vue';
import AdminEmailsForm from './components/admin_emails_form.vue';

export const initAdminEmailsForm = () => {
  const el = document.getElementById('js-admin-emails-form');

  if (!el) {
    return null;
  }

  const { adminEmailPath, adminEmailsAreCurrentlyRateLimited } = el.dataset;

  return new Vue({
    el,
    provide: {
      adminEmailPath,
      adminEmailsAreCurrentlyRateLimited,
    },
    render(h) {
      return h(AdminEmailsForm);
    },
  });
};
