#!/usr/bin/env bash

source src/bash-base.sh

shellScriptFile="src/bash-base.sh"
referencesMarkdownFile="docs/references.md"
referencesManPageFile="man/bash-base.1"

./scripts/lint-comment.sh

# generate references markdown from script comment
rm -fr "${referencesMarkdownFile}"
doc_comment_to_markdown "${shellScriptFile}" "${referencesMarkdownFile}"

# Use pandoc to generate man page from markdown, use man section 1
rm -fr "${referencesManPageFile}"
docker run --rm --volume "$(pwd):/data" --user "$(id -u):$(id -g)" pandoc/core:2.10 \
	-f markdown \
	-t man \
	--standalone \
	--variable=section:1 \
	--variable=header:"bash-base functions reference" \
	"${referencesMarkdownFile}" \
	-o "${referencesManPageFile}"

# print the result of man page
man -P cat "${referencesManPageFile}"
