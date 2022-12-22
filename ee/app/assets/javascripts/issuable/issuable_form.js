import groupsSelect from '~/groups_select';
import IssuableForm from '~/issuable/issuable_form';

export default class IssuableFormEE extends IssuableForm {
  constructor(form) {
    super(form);

    groupsSelect();
  }

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
