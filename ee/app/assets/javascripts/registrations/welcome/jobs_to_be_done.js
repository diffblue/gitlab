const select = document.querySelector('.js-jobs-to-be-done-dropdown');
if (select) {
  select.addEventListener('change', () => {
    const otherSelected = select.value === 'other';
    document
      .querySelector('.js-jobs-to-be-done-other-group')
      .classList.toggle('hidden', !otherSelected);
  });
}
