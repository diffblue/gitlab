import { isEqual } from 'lodash';
import { stripTypenames } from 'helpers/graphql_helpers';

export function toEqualGraphqlFixture(received, match) {
  let clearMatch;

  try {
    clearMatch = stripTypenames(match);
  } catch (e) {
    return { message: 'The comparator value is not an object', pass: false };
  }
  const pass = isEqual(received, clearMatch);
  const message = pass
    ? () => `
        Expected to not be: ${this.utils.printExpected(clearMatch)}
        Received:           ${this.utils.printReceived(received)}
        `
    : () =>
        `
      Expected to be: ${this.utils.printExpected(clearMatch)}
      Received:       ${this.utils.printReceived(received)}
      `;

  return { actual: received, message, pass };
}
