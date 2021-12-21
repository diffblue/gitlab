export default function setupTransferEdit(formSelector, watchField, targetSelectorId) {
  const transferForm = document.querySelector(formSelector);
  console.log('formSelector', formSelector);
  console.log('watchField', watchField);
  console.log('transferForm', transferForm);
  const field = transferForm.querySelector(watchField);
  console.log('field', field);
  const valueField = transferForm.querySelector(targetSelectorId);
  console.log('valueField.value', valueField.value);

  field.addEventListener('click', (e) => {
    console.log('event::click');

    console.log('valueField', valueField, valueField.value);
    console.log('e', e.currentTarget);
    console.log('e', e.target);
    transferForm
      .querySelector("input[type='submit']")
      // .querySelector("input[type='submit']")
      .setAttribute('disabled', !valueField.val() ? 'disabled' : '');
  });

  field.addEventListener('select', () => {
    console.log('event::select');
    // transferForm
    //   .querySelector("input[type='submit']")
    //   .setAttribute('disabled', !field.val() ? 'disabled' : '');
  });

  field.addEventListener('change', () => {
    console.log('event::change');
    // transferForm
    //   .querySelector("input[type='submit']")
    //   .setAttribute('disabled', !field.val() ? 'disabled' : '');
  });
  // field.trigger('change');
  transferForm.querySelector("input[type='submit']").setAttribute('disabled', 'disabled');
}
