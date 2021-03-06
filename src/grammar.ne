@{%
  const appendItem = (a, b) => d => d[a].concat([d[b]]);
  const appendItemChar = (a, b) => d => d[a].concat(d[b]);

  const flatten = d => {
    d = d.filter((r) => { return r !== null; });
    return d.reduce(
      (a, b) => {
        return a.concat(b);
      },
      []
    );
  };

  const combinatorMap = {
    ' ': 'descendantCombinator',
    '+': 'adjacentSiblingCombinator',
    '>': 'childCombinator',
    '~': 'generalSiblingCombinator'
  };

  const concatUsingCombinator = d => {
    return (
        Array.isArray(d[0]) ? d[0] : [d[0]]
      )
      .concat({
        type: combinatorMap[d[2]]
      })
      .concat(d[4]);
  };
%}

combinator ->
  selector
  | combinator _ [>+~ ] _ selector {% concatUsingCombinator %}

selector -> selectorBody {% d => ({type: 'selector', body: d[0]}) %}

selectorBody ->
    typeSelector:? idSelector:? classSelector:* attributeValueSelector:* attributePresenceSelector:* pseudoClassSelector:* pseudoElementSelector:? {% (d, i, reject) => { const selectors = flatten(d); if (!selectors.length) return reject; return selectors; } %}
  | universalSelector idSelector:? classSelector:* attributeValueSelector:* attributePresenceSelector:* pseudoClassSelector:* pseudoElementSelector:? {% flatten %}

typeSelector -> attributeName {% d => ({type: 'typeSelector', name: d[0]}) %}

# see http://stackoverflow.com/a/449000/368691
className -> "-":? [_a-zA-Z] [_a-zA-Z0-9-]:* {% d => (d[0] || '') + d[1] + d[2].join('') %}

attributeName -> [_a-zA-Z] [_a-zA-Z0-9-]:* {% d => d[0] + d[1].join('') %}

classSelector -> "." className {% d => ({type: 'classSelector', name: d[1]}) %}

# The selector used for ID name does not permit all valid HTML5 ID names.
# In HTML5 ID value can be any string that does not include a space.
# @see https://www.w3.org/TR/2011/WD-html5-20110525/elements.html#the-id-attribute
#
# I have not seen special characters being used in ID.
# Therefore, for simplicity, attributeName regex is used here.
#
# If we were to respect HTML5 spec, we'd need to accomodate all special characters,
# including [>+~:#. ].
idSelector -> "#" attributeName {% d => ({type: 'idSelector', name: d[1]}) %}

universalSelector -> "*" {% d => ({type: 'universalSelector'}) %}

attributePresenceSelector -> "[" attributeName "]" {% d => ({type: 'attributePresenceSelector', name: d[1]}) %}

attributeOperator ->
  "=" |
  "~=" |
  "|=" |
  "^=" |
  "$=" |
  "*="

attributeValueSelector -> "[" attributeName attributeOperator attributeValue "]"

{%
  d => ({
    type: 'attributeValueSelector',
    name: d[1],
    value: d[3],
    operator: d[2][0]
  })
%}

attributeValue ->
    unquotedAttributeValue {% id %}
  | sqstring {% id %}
  | dqstring {% id %}

unquotedAttributeValue ->
  [^\[\]"',= ]:+ {% d => d[0].join('') %}

classParameters ->
    null
  | classParameter
  | classParameters "," _ classParameter {% appendItem(0, 3) %}

classParameter ->
    [^()"', ]:+ {% d => d[0].join('') %}
  | sqstring {% id %}
  | dqstring {% id %}

pseudoElementSelector ->
    "::" pseudoClassSelectorName {% d => ({type: 'pseudoElementSelector', name: d[1]}) %}

pseudoClassSelector ->
    ":" pseudoClassSelectorName {% d => ({type: 'pseudoClassSelector', name: d[1]}) %}
  | ":" pseudoClassSelectorName "(" classParameters ")" {% d => ({type: 'pseudoClassSelector', name: d[1], parameters: d[3]}) %}

pseudoClassSelectorName ->
  [a-zA-Z] [a-zA-Z0-9-_]:+ {% d => d[0] + d[1].join('') %}

dqstring ->
  "\"" dstrchar:* "\"" {% d => d[1].join('') %}

dstrchar ->
    [^"] {% id %}
  | "\\\"" {% d => '"' %}

sqstring ->
  "'" sstrchar:* "'" {% d => d[1].join('') %}

sstrchar ->
    [^'] {% id %}
  | "\\'" {% d => '\'' %}

_ ->
  [ ]:* {% d => null %}
