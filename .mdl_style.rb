# Start with all built-in rules.
# https://github.com/markdownlint/markdownlint/blob/master/docs/RULES.md
all

# Ignore line length in table blocks.
# https://github.com/markdownlint/markdownlint/blob/master/docs/RULES.md#md013---line-length
rule 'MD013', tables: false, code: false
