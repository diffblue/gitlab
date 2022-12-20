import $ from 'jquery';
import '~/lib/utils/jquery_at_who';
import GfmAutoComplete, { showAndHideHelper, escape } from '~/gfm_auto_complete';

/**
 * This is added to keep the export parity with the CE counterpart.
 *
 * Some modules import `defaultAutocompleteConfig` or `membersBeforeSave`
 * which will be undefined if not exported from here in EE.
 */
export {
  escape,
  defaultAutocompleteConfig,
  membersBeforeSave,
  highlighter,
  CONTACT_STATE_ACTIVE,
  CONTACTS_ADD_COMMAND,
  CONTACTS_REMOVE_COMMAND,
} from '~/gfm_auto_complete';

const EPICS_ALIAS = 'epics';
const ITERATIONS_ALIAS = 'iterations';
const VULNERABILITIES_ALIAS = 'vulnerabilities';

GfmAutoComplete.Iterations = {
  templateFunction({ id, title }) {
    return `<li><small>*iteration:${id}</small> ${escape(title)}</li>`;
  },
};

class GfmAutoCompleteEE extends GfmAutoComplete {
  setupAtWho($input) {
    if (this.enableMap.epics) {
      this.setupAutoCompleteEpics($input, this.getDefaultCallbacks());
    }

    if (this.enableMap.iterations) {
      this.setupAutoCompleteIterations($input, this.getDefaultCallbacks());
    }

    if (this.enableMap.vulnerabilities) {
      this.setupAutoCompleteVulnerabilities($input, this.getDefaultCallbacks());
    }

    super.setupAtWho($input);
  }

  // eslint-disable-next-line class-methods-use-this
  setupAutoCompleteEpics = ($input, defaultCallbacks) => {
    $input.atwho({
      at: '&',
      alias: EPICS_ALIAS,
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
    showAndHideHelper($input, EPICS_ALIAS);
  };

  // eslint-disable-next-line class-methods-use-this
  setupAutoCompleteIterations = ($input, defaultCallbacks) => {
    $input.atwho({
      at: '*iteration:',
      alias: ITERATIONS_ALIAS,
      searchKey: 'search',
      displayTpl(value) {
        let tmpl = GfmAutoComplete.Loading.template;
        if (value.id != null) {
          tmpl = GfmAutoComplete.Iterations.templateFunction(value);
        }
        return tmpl;
      },
      data: GfmAutoComplete.defaultLoadingData,
      // eslint-disable-next-line no-template-curly-in-string
      insertTpl: '${atwho-at}${id}',
      skipSpecialCharacterTest: true,
      callbacks: {
        ...defaultCallbacks,
        beforeSave(merges) {
          return $.map(merges, (m) => {
            if (m.id == null) {
              return m;
            }

            return {
              id: m.id,
              title: m.title,
              search: `${m.id} ${m.title}`,
            };
          });
        },
      },
    });
    showAndHideHelper($input, ITERATIONS_ALIAS);
  };

  // eslint-disable-next-line class-methods-use-this
  setupAutoCompleteVulnerabilities = ($input, defaultCallbacks) => {
    $input.atwho({
      at: '[vulnerability:',
      suffix: ']',
      alias: VULNERABILITIES_ALIAS,
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
    showAndHideHelper($input, VULNERABILITIES_ALIAS);
  };
}

export default GfmAutoCompleteEE;
