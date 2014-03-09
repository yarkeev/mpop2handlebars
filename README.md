Translate templates from mpop syntax to handlebars syntax

## Example:
```
TemplateTranslator = require('mpop2handlebars');
templateTranslator = new TemplateTranslator(mpopCode);
handlebarsCode = templateTranslator.toHandleBars();
```