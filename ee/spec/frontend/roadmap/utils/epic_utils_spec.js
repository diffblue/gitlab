import * as epicUtils from 'ee/roadmap/utils/epic_utils';

describe('addIsChildEpicTrueProperty', () => {
  const title = 'Lorem ipsum dolar sit';
  const description = 'Beatae suscipit dolorum nihil quidem est accusamus';
  const obj = {
    title,
    description,
  };
  let newObj;

  beforeEach(() => {
    newObj = epicUtils.addIsChildEpicTrueProperty(obj);
  });

  it('adds `isChildEpic` property with value `true`', () => {
    expect(newObj.isChildEpic).toBe(true);
  });

  it('has original properties in returned object', () => {
    expect(newObj.title).toBe(title);
    expect(newObj.description).toBe(description);
  });
});

describe('generateKey', () => {
  it('returns epic namespaced key for an epic object', () => {
    const obj = {
      id: 3,
      title: 'Lorem ipsum dolar sit',
      isChildEpic: false,
    };

    expect(epicUtils.generateKey(obj)).toBe('epic-3');
  });

  it('returns child-epic- namespaced key for a child epic object', () => {
    const obj = {
      id: 3,
      title: 'Lorem ipsum dolar sit',
      isChildEpic: true,
    };

    expect(epicUtils.generateKey(obj)).toBe('child-epic-3');
  });
});

describe('scrollToCurrentDay', () => {
  it('scrolls current day indicator into view', () => {
    const currentDayIndicator = document.createElement('div');
    currentDayIndicator.classList.add('js-current-day-indicator');
    document.body.appendChild(currentDayIndicator);

    jest.spyOn(currentDayIndicator, 'scrollIntoView').mockImplementation();

    epicUtils.scrollToCurrentDay(document.body);

    expect(currentDayIndicator.scrollIntoView).toHaveBeenCalledWith({
      block: 'nearest',
      inline: 'center',
    });
  });
});

describe('transformFetchEpicFilterParams', () => {
  it('should return congregated `not[]` params in a single key', () => {
    const filterParams = {
      'not[authorUsername]': 'foo',
      'not[myReactionEmoji]': ':emoji:',
      authorUsername: 'baz',
    };

    expect(epicUtils.transformFetchEpicFilterParams(filterParams)).toEqual({
      not: {
        authorUsername: 'foo',
        myReactionEmoji: ':emoji:',
      },
      authorUsername: 'baz',
    });
  });

  it('should return congregated `or[]` params in a single key', () => {
    const filterParams = {
      'or[labelName]': ['foo', 'bar'],
      'or[authorUsername]': ['boo', 'baa'],
      authorUsername: 'baz',
    };

    expect(epicUtils.transformFetchEpicFilterParams(filterParams)).toEqual({
      or: {
        labelName: ['foo', 'bar'],
        authorUsername: ['boo', 'baa'],
      },
      authorUsername: 'baz',
    });
  });
});
