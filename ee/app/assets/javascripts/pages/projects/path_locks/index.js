import initDeprecatedRemoveRowBehavior from '~/behaviors/deprecated_remove_row_behavior';

initDeprecatedRemoveRowBehavior();

const locks = document.querySelector('.locks');

locks.addEventListener('ajax:success', () => {
  const allRowsHidden = [...locks.querySelectorAll('li')].every((x) => x.offsetParent === null);

  if (allRowsHidden) {
    locks.querySelector('.nothing-here-block.hidden')?.classList?.remove('hidden');
  }
});
