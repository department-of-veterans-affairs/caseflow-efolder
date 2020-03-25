module.exports = {
  env: {
    browser: true
  },
  extends: ['@department-of-veterans-affairs/eslint-config-appeals'],
  parserOptions: {
    ecmaFeatures: {
      jsx: true
    },
    ecmaVersion: 10,
    sourceType: 'module'
  },
  settings: {
    react: {
      version: '16.12'
    },
    'import/resolver': {
      node: {
        extensions: ['.js', '.jsx', '.json']
      }
    }
  }
};
