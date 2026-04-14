module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "quotes": ["error", "double"],
    "indent": ["error", 2],
    "max-len": ["warn", {code: 120}],
    "require-jsdoc": "off",
    "valid-jsdoc": "off",
    "comma-dangle": ["error", "always-multiline"],
    "object-curly-spacing": ["error", "never"],
  },
  parserOptions: {
    ecmaVersion: 2020,
  },
};
