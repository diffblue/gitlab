import $ from 'jquery';
import '~/lib/utils/jquery_at_who';
import GfmAutoComplete from '~/gfm_auto_complete';

/**
 * This is added to keep the export parity with the CE counterpart.
 *
 * Some modules import `defaultAutocompleteConfig` or `membersBeforeSave`
 * which will be undefined if not exported from here in EE.
 */
export { defaultAutocompleteConfig, membersBeforeSave } from '~/gfm_auto_complete';

class GfmAutoCompleteEE extends GfmAutoComplete {
  setupAtWho($input) {
    if (this.enableMap.epics) {
      this.setupAutoCompleteEpics($input, this.getDefaultCallbacks());
    }

    if (this.enableMap.vulnerabilities) {
      this.setupAutoCompleteVulnerabilities($input, this.getDefaultCallbacks());
    }

    super.setupAtWho($input);
  }

  setupAutoCompleteEpics = ($input, defaultCallbacks) => {
    $input.atwho({
      at: '&',
      alias: 'epics',
      searchKey: 'search',
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Loading.template;
        if (value.title != null) {
          tmpl = GfmAutoComplete.Issues.templateFunction(value);
        }
        return tmpl;
      },
      data: GfmAutoComplete.defaultLoadingData,
      insertTpl: GfmAutoComplete.Issues.insertTemplateFunction,
      skipSpecialCharacterTest: true,
      callbacks: {
        ...defaultCallbacks,
        beforeSave(merges) {
          return $.map(merges, (m) => {
            if (m.title == null) {
              return m;
            }
            return {
              id: m.iid,
              reference: m.reference,
              title: m.title,
              search: `${m.iid} ${m.title}`,
            };
          });
        },
      },
    });
  };

  setupAutoCompleteVulnerabilities = ($input, defaultCallbacks) => {
    $input.atwho({
      at: '[vulnerability:',
      suffix: ']',
      alias: 'vulnerabilities',
      searchKey: 'search',
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Loading.template;
        if (value.title != null) {
          tmpl = GfmAutoComplete.Issues.templateFunction(value);
        }
        return tmpl;
      },
      data: GfmAutoComplete.defaultLoadingData,
      insertTpl: GfmAutoComplete.Issues.insertTemplateFunction,
      skipSpecialCharacterTest: true,
      callbacks: {
        ...defaultCallbacks,
        beforeSave(merges) {
          return merges.map((m) => {
            if (m.title == null) {
              return m;
            }
            return {
              id: m.id,
              title: m.title,
              reference: m.reference,
              search: `${m.id} ${m.title}`,
            };
          });
        },
      },
    });
  };
}

export default GfmAutoCompleteEE;
