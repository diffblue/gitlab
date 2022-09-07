import Autosave from '~/autosave';
import groupsSelect from '~/groups_select';
import IssuableForm from '~/issuable/issuable_form';

export default class IssuableFormEE extends IssuableForm {
  constructor(form) {
    super(form);

    groupsSelect();
  }

  initAutosave() {
    super.initAutosave();

    const weightField = this.form.find('input[name*="[weight]"]');
    if (weightField.length) {
      this.autosaveWeight = new Autosave(
        weightField,
        [document.location.pathname, this.searchTerm, 'weight'],
        `${this.fallbackKey}=weight`,
      );
    }
  }

  resetAutosave() {
    super.resetAutosave();

    if (this.autosaveWeight) this.autosaveWeight.reset();
  }
}
