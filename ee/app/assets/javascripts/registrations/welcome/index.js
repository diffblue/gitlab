export const initWelcomeIndex = () => {
  const emailUpdatesForm = document.querySelector('.js-opt-in-to-email');
  const setupForCompany = document.querySelector('.js-setup-for-company');
  const setupForMe = document.querySelector('.js-setup-for-me');

  if (emailUpdatesForm) {
    if (setupForCompany) {
      setupForCompany.addEventListener('change', () => {
        emailUpdatesForm.classList.add('hidden');
      });
    }

    if (setupForMe) {
      setupForMe.addEventListener('change', () => {
        emailUpdatesForm.classList.remove('hidden');
      });
    }
  }
};
