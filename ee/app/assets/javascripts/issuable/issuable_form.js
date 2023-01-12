import IssuableForm from '~/issuable/issuable_form';

export default class IssuableFormEE extends IssuableForm {
  initAutosave() {
    const autoSaveMap = super.initAutosave();

    IssuableForm.addAutosave(
      autoSaveMap,
      'weight',
      this.form.find('input[name*="[weight]"]').get(0),
      this.searchTerm,
      this.fallbackKey,
    );

    return autoSaveMap;
  }
}
