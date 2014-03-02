class HandleBarsConditionTranslator

	regVar: new RegExp /<!-*\s*if\s*(\w*)/i

	regUnless: new RegExp /<!-*\s*if\s*!(\w*)/i

	regEq: new RegExp /<!-*\s*if\s*(Eq[2]?)\((\w*),(\w*)\)/i

	regLt: new RegExp /<!-*\s*if\s*(Lt[2]?)\((\w*),(\w*)\)/i

	regGt: new RegExp /<!-*\s*if\s*(Gt[2]?)\((\w*),(\w*)\)/i

	start: (template) ->
		if @regEq.test template
			arCond = template.match @regEq
			"{{#ifEq #{arCond[2]} #{arCond[3]}}"
		else if @regLt.test template
			arCond = template.match @regLt
			"{{#ifLt #{arCond[2]} #{arCond[3]}}}"
		else if @regGt.test template
			arCond = template.match @regGt
			"{{#ifGt #{arCond[2]} #{arCond[3]}}}"
		else if @regUnless.test template
			arCond = template.match @regUnless
			"{{#unless #{arCond[1]}}}"
		else if @regVar.test template
			arCond = template.match @regVar
			"{{#if #{arCond[1]}}}"

	end: (template) ->
		if @regEq.test template
			"{{/ifEq}}"
		else if @regLt.test template
			"{{/ifLt}}"
		else if @regGt.test template
			"{{/ifGt}}"
		else if @regUnless.test template
			"{{/unless}}"
		else if @regVar.test template
			"{{/if}}"

class HandleBarsLoopTranslator

	regFor: new RegExp /<!-*\s*for\s*(\w*)/i

	start: (template) ->
		if @regFor.test template
			arCond = template.match @regFor
			"{{#each #{arCond[1]}}}"

	end: (template) ->
		if @regFor.test template
			"{{/each}}"

class HandleBarsElseTranslator

	regElse: new RegExp /<!-*\s*else\s*-*>/ig

	start: (template) ->
		template.replace @regElse, "{{else}}"

class HandleBarsVariableTranslator

	regVar: new RegExp /##\.?(.*?)##/g

	start: (template) ->
		template.replace @regVar, "{{$1}}"


class HandleBarsBuilder

	constructor: (templateTree) ->
		@tree = templateTree
		@conditionTranslator = new HandleBarsConditionTranslator
		@loopTranslator = new HandleBarsLoopTranslator
		@elseTranslator = new HandleBarsElseTranslator
		@variableTranslator = new HandleBarsVariableTranslator
		@result = ''
		@translateNode @tree.root

	translateNode: (node) ->
		for item in node.children
			@result += '\n' + @translateCode(item)
			if !item.isSimple
				@translateNode item

	translateCode: (item) ->
		result = item.code
		if item.isCond
			result = @conditionTranslator.start item.code
		else if item.isClosed && item.startItem.isCond
			result = @conditionTranslator.end item.startItem.code
		else if item.isLoop
			result = @loopTranslator.start item.code
		else if item.isClosed && item.startItem.isLoop
			result = @loopTranslator.end item.startItem.code
		result = @elseTranslator.start result
		result = @variableTranslator.start result

	get: ->
		@result



class TemplateTreeItem

	regCond: new RegExp /<!-*\s*if/ig
	regElse: new RegExp /<!-*\s*else/ig
	regLoop: new RegExp /<!-*\s*for/ig
	regEndCond: new RegExp /<!-*\s*\/if/ig
	regEndLoop: new RegExp /<!-*\s*\/for/ig

	constructor: (code) ->
		@children = []
		@code = code
		@isSimple = @code.indexOf('<!--') == -1
		@isCond = @code.search(@regCond) != -1
		@isElse = @code.search(@regElse) != -1
		@isLoop = @code.search(@regLoop) != -1
		@isEndCond = @code.search(@regEndCond) != -1
		@isEndLoop = @code.search(@regEndLoop) != -1

	addChild: (item) ->
		@children.push item

	isClose: (item) ->
		@isCond && item.isEndCond || @isLoop && item.isEndLoop

class TemplateBlockList

	constructor: ->
		@blocks = []
		@index = 0

	push: (item) ->
		@blocks.push item

	next: ->
		if @index + 1 > @getLength()
			null
		else
			@blocks[@index++]

	getLength: ->
		@blocks.length

class TemplateTree

	regStart: new RegExp /<!--/ig
	regEnd: new RegExp /<!--\s*\//ig
	regClose: new RegExp /-->/ig

	constructor: (template) ->
		@source = template
		@_template = template
		@blocks = new TemplateBlockList

		while block = @getNextBlock()
			if block
				@blocks.push new TemplateTreeItem(block)
		@buildTree()

	buildTree: ->
		@root = new TemplateTreeItem ''
		@buildNode @root


	buildNode: (item) ->
		while block = @blocks.next()
			item.addChild block
			if item.isClose block
				block.isClosed = true
				block.startItem = item
				break
			else if !block.isSimple && !block.isElse
				@buildNode block

	getNextBlock: ->
		posStart = @_template.search @regStart
		posEnd = @_template.search @regEnd
		pos = Math.min posStart, posEnd
		if pos == 0
			pos = @_template.search(@regClose) + 3
		block = @_template.substr 0, pos

		if pos == -1
			if !@_last
				block = @_template
				@_last = true
			else
				block = null
		@_template = @_template.substr pos

		return block


class TemplateTranslator

	constructor: (template) ->
		@source = template
		@buildTree()

	buildTree: ->
		@tree = new TemplateTree @source

	toHandleBars: ->
		new HandleBarsBuilder(@tree).get()

s = 'qweqeqwqrqw' + 
'<!-- IF    Eq(Var1,Var2)    -->' +
'dfsdfd' +
'<!-- /IF -->' +
'<!-- IF    Var2    -->' +
'fgf' +
'<!-- /IF -->' +
'<!-- FOR ITEMS -->' +
'##.qweqwe##' +
'<!-- /FOR -->' +
'qweqweqwe
<div style="background-image: url(##AuthorAvatar##)" class="b-photo__content-author">
    <a data-clns="d713149" href="http://##MyMailHost####AuthorDir##" type="booster" class="booster-sc b-photo__content-author-name" name="clb1485859">
        <!-- IF AuthorName -->##AuthorName##<!-- ELSE --->##AuthorEmail##<!-- /IF -->
        <!-- IF JournalIsVipUser -->
            qwe
        <!-- /IF -->
    </a>
    <span class="b-photo__content-addtime">загружено ##image_AddTime_d##.##image_AddTime_m##.##image_AddTime_Y##</span>
</div>
<!-- IF !JournalIsCommunity -->
	<div class="b-photo__content-album">
	    Альбом: <a data-clns="d713148" type="booster" href="http://##MyMailHost##/##PhotoDomainAlias##/##PhotoUser##/photo?album_id=##album_id##" class="b-photo__content-albumlink booster-sc"><!-- IF album_Name -->##album_Name##<!-- ELSE -->Без названия<!-- /IF --></a>
	</div>
<!-- /IF -->
<!--   FOR items --->
	##.name##
	##.id##
<!-- /FOR -->
'


builder = new TemplateTranslator s
console.log(builder.toHandleBars())