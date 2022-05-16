import $ from 'jquery';
import createFlash from '~/flash';
import { loadCSSFile } from '~/lib/utils/css_utils';
import { __ } from '~/locale';
import MirrorRepos from '~/mirrors/mirror_repos';

export default class EEMirrorRepos extends MirrorRepos {
  constructor(...args) {
    super(...args);

    this.$mirrorDirectionSelect = $('.js-mirror-direction', this.$form);
    this.$insertionPoint = $('.js-form-insertion-point', this.$form);
    this.$repoCount = $('.js-mirrored-repo-count', this.$container);
    this.directionFormMap = {
      push: $('.js-push-mirrors-form', this.$form).html(),
      pull: $('.js-pull-mirrors-form', this.$form).html(),
    };
  }

  init() {
    this.$insertionPoint.collapse({
      toggle: false,
    });
    this.handleUpdate();
    super.init();
  }

  handleUpdate() {
    return this.hideForm()
      .then(() => {
        this.updateForm();
        this.showForm();
      })
      .catch(() => {
        createFlash({
          message: __('Something went wrong on our end.'),
        });
      });
  }

  hideForm() {
    return new Promise((resolve) => {
      if (!this.$insertionPoint.html()) {
        resolve();
      }

      this.$insertionPoint.one('hidden.bs.collapse', () => {
        resolve();
      });

      this.$insertionPoint.collapse('hide');
    });
  }

  showForm() {
    return new Promise((resolve) => {
      this.$insertionPoint.one('shown.bs.collapse', () => {
        resolve();
      });
      this.$insertionPoint.collapse('show');
    });
  }

  updateForm() {
    const direction = this.$mirrorDirectionSelect.val();

    this.$insertionPoint.collapse('hide');
    this.$insertionPoint.html(this.directionFormMap[direction]);
    this.$insertionPoint.collapse('show');

    this.updateUrl();
    this.updateProtectedBranches();

    if (this.sshMirror) this.sshMirror.destroy();
    if (direction === 'pull') return this.initMirrorPull();
    return this.initMirrorPush();
  }

  initMirrorPull() {
    this.initMirrorSSH();
    this.initSelect2();
  }

  initSelect2() {
    import(/* webpackChunkName: 'select2' */ 'select2/select2')
      .then(() => {
        loadCSSFile(gon.select2_css_path);
      })
      .then(() => {
        $('.js-mirror-user', this.$form).select2({
          width: 'resolve',
          dropdownAutoWidth: true,
        });
      })
      .catch(() => {});
  }

  registerUpdateListeners() {
    super.registerUpdateListeners();
    this.$mirrorDirectionSelect.on('change', () => this.handleUpdate());
  }

  deleteMirror(event) {
    const $target = $(event.currentTarget);
    const isPullMirror = $target.hasClass('js-delete-pull-mirror');
    let payload;

    if (isPullMirror) {
      payload = {
        project: {
          mirror: false,
        },
      };
    }

    return super.deleteMirror(event, payload).then(() => {
      if (isPullMirror) this.$mirrorDirectionSelect.removeAttr('disabled');
    });
  }

  removeRow($target) {
    super.removeRow($target);

    const currentCount = parseInt(this.$repoCount.text().replace(/(\(|\))/, ''), 10);
    this.$repoCount.text(`(${currentCount - 1})`);
  }
}
