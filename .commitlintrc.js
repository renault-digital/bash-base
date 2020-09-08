const { types } = require('conventional-commit-types');

module.exports = {
    extends: ['@commitlint/config-conventional'], // issuePrefixes: ['#']
    rules: {
        // Follow the commit-types used by commitizen (https://git.io/Je4pr).
        'type-enum': [2, 'always', Object.keys(types)],
        'body-max-line-length': [2, 'always', 150],
        'footer-max-line-length': [2, 'always', 200],
    },
};
