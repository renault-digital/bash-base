module.exports = {
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    ["@semantic-release/git", {
      "assets": ['CHANGELOG.md', 'package.json', 'package-lock.json', 'npm-shrinkwrap.json', 'docs/references.md', 'man/bash-base.1'],
      "message": "chore(release): ${nextRelease.version} [skip ci]"
    }],
    ["@semantic-release/exec", {
      "prepareCmd": "docker build -t renaultdigital/bash-base . && npm run livedoc"
    }],
    ["semantic-release-docker", {
      "name": "renaultdigital/bash-base"
    }]
  ]
}
