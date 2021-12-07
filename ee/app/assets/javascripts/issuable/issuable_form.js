import groupsSelect from '~/groups_select';
import IssuableForm from '~/issuable/issuable_form';

export default class IssuableFormEE extends IssuableForm {
  constructor(form) {
    super(form);

    groupsSelect();
  }
}
