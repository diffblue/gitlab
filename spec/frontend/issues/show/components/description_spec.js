import $ from 'jquery';
import Vue, { nextTick } from 'vue';
import '~/behaviors/markdown/render_gfm';
import { TEST_HOST } from 'helpers/test_constants';
import mountComponent from 'helpers/vue_mount_component_helper';
import Description from '~/issues/show/components/description.vue';
import TaskList from '~/task_list';
import { descriptionProps as props } from '../mock_data/mock_data';

jest.mock('~/task_list');

describe('Description component', () => {
  let vm;
  let DescriptionComponent;

  beforeEach(() => {
    DescriptionComponent = Vue.extend(Description);

    if (!document.querySelector('.issuable-meta')) {
      const metaData = document.createElement('div');
      metaData.classList.add('issuable-meta');
      metaData.innerHTML =
        '<div class="flash-container"></div><span id="task_status"></span><span id="task_status_short"></span>';

      document.body.appendChild(metaData);
    }

    vm = mountComponent(DescriptionComponent, props);
  });

  afterEach(() => {
    vm.$destroy();
  });

  afterAll(() => {
    $('.issuable-meta .flash-container').remove();
  });

  it('doesnt animate first description changes', async () => {
    vm.descriptionHtml = 'changed';

    await nextTick();
    expect(vm.$el.querySelector('.md').classList.contains('issue-realtime-pre-pulse')).toBeFalsy();
    jest.runAllTimers();
  });

  it('animates description changes on live update', async () => {
    vm.descriptionHtml = 'changed';
    await nextTick();
    vm.descriptionHtml = 'changed second time';
    await nextTick();
    expect(vm.$el.querySelector('.md').classList.contains('issue-realtime-pre-pulse')).toBeTruthy();
    jest.runAllTimers();
    await nextTick();
    expect(
      vm.$el.querySelector('.md').classList.contains('issue-realtime-trigger-pulse'),
    ).toBeTruthy();
  });

  it('applies syntax highlighting and math when description changed', async () => {
    const vmSpy = jest.spyOn(vm, 'renderGFM');
    const prototypeSpy = jest.spyOn($.prototype, 'renderGFM');
    vm.descriptionHtml = 'changed';

    await nextTick();
    expect(vm.$refs['gfm-content']).toBeDefined();
    expect(vmSpy).toHaveBeenCalled();
    expect(prototypeSpy).toHaveBeenCalled();
    expect($.prototype.renderGFM).toHaveBeenCalled();
  });

  it('sets data-update-url', () => {
    expect(vm.$el.querySelector('textarea').dataset.updateUrl).toEqual(TEST_HOST);
  });

  describe('TaskList', () => {
    beforeEach(() => {
      vm.$destroy();
      TaskList.mockClear();
      vm = mountComponent(DescriptionComponent, { ...props, issuableType: 'issuableType' });
    });

    it('re-inits the TaskList when description changed', () => {
      vm.descriptionHtml = 'changed';

      expect(TaskList).toHaveBeenCalled();
    });

    it('does not re-init the TaskList when canUpdate is false', () => {
      vm.canUpdate = false;
      vm.descriptionHtml = 'changed';

      expect(TaskList).toHaveBeenCalledTimes(1);
    });

    it('calls with issuableType dataType', () => {
      vm.descriptionHtml = 'changed';

      expect(TaskList).toHaveBeenCalledWith({
        dataType: 'issuableType',
        fieldName: 'description',
        selector: '.detail-page-description',
        onUpdate: expect.any(Function),
        onSuccess: expect.any(Function),
        onError: expect.any(Function),
        lockVersion: 0,
      });
    });
  });

  describe('taskStatus', () => {
    it('adds full taskStatus', async () => {
      vm.taskStatus = '1 of 1';

      await nextTick();
      expect(document.querySelector('.issuable-meta #task_status').textContent.trim()).toBe(
        '1 of 1',
      );
    });

    it('adds short taskStatus', async () => {
      vm.taskStatus = '1 of 1';

      await nextTick();
      expect(document.querySelector('.issuable-meta #task_status_short').textContent.trim()).toBe(
        '1/1 task',
      );
    });

    it('clears task status text when no tasks are present', async () => {
      vm.taskStatus = '0 of 0';

      await nextTick();
      expect(document.querySelector('.issuable-meta #task_status').textContent.trim()).toBe('');
    });
  });

  describe('taskListUpdateStarted', () => {
    it('emits event to parent', () => {
      const spy = jest.spyOn(vm, '$emit');

      vm.taskListUpdateStarted();

      expect(spy).toHaveBeenCalledWith('taskListUpdateStarted');
    });
  });

  describe('taskListUpdateSuccess', () => {
    it('emits event to parent', () => {
      const spy = jest.spyOn(vm, '$emit');

      vm.taskListUpdateSuccess();

      expect(spy).toHaveBeenCalledWith('taskListUpdateSucceeded');
    });
  });

  describe('taskListUpdateError', () => {
    it('should create flash notification and emit an event to parent', () => {
      const msg =
        'Someone edited this issue at the same time you did. The description has been updated and you will need to make your changes again.';
      const spy = jest.spyOn(vm, '$emit');

      vm.taskListUpdateError();

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(msg);
      expect(spy).toHaveBeenCalledWith('taskListUpdateFailed');
    });
  });
});
