export function initRemoveButtonBehavior() {
  const emptyState = document.querySelector('.js-domain-empty-state');

  function removeRowSuccessCallback() {
    this.closest('tr').classList.add('gl-display-none!');

    const labelsCount = document.querySelectorAll('.js-domain-row:not(.gl-display-none\\!)').length;

    if (labelsCount < 1 && emptyState) {
      emptyState.classList.remove('gl-display-none');
    }
  }

  document.querySelectorAll('.js-remove-domain').forEach((button) => {
    button.addEventListener('ajax:success', removeRowSuccessCallback);
  });
}
