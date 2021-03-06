define [
  'i18n!discussions'
  'compiled/arr/walk'
  'Backbone'
  'jst/discussions/EntryCollectionView'
  'jst/discussions/entryStats'
  'compiled/views/DiscussionTopic/EntryView'
], (I18n, walk, {View}, template, entryStats, EntryView) ->

  class EntryCollectionView extends View

    defaults:
      descendants: 2
      showMoreDescendants: 2
      showReplyButton: false
      displayShowMore: true

      # maybe make a sub-class for threaded discussions if the branching gets
      # out of control
      threaded: false

      # its collection represents the root of the discussion, should probably
      # be a subclass instead :\
      root: false

    events:
      'click .loadNext': 'loadNextFromEvent'

    template: template

    els: '.discussion-entries': 'list'

    initialize: ->
      super
      @attach()

    attach: ->
      @collection.on 'reset', @addAll
      @collection.on 'add', @add

    toJSON: -> @options

    addAll: =>
      @teardown()
      @collection.each @add

    add: (entry) =>
      view = new EntryView
        model: entry
        treeView: @constructor
        descendants: @options.descendants
        children: @collection.options.perPage
        showMoreDescendants: @options.showMoreDescendants
        threaded: @options.threaded
      view.render()
      return @addNewView view if entry.get 'new'
      if @options.descendants
        view.renderTree()
      else if entry.hasChildren()
        view.renderDescendantsLink()
      if !@options.threaded and !@options.root
        @list.prepend view.el
      else
        @list.append view.el

    addNewView: (view) ->
      view.model.set 'new', false
      if @options.threaded
        @list.prepend view.el
      else
        @list.append view.el
      if not @options.root
        view.$el.hide()
        setTimeout =>
          view.$el.fadeIn()
        , 500

    teardown: ->
      @list.empty()

    afterRender: ->
      super
      @addAll()
      @renderNextLink()

    renderNextLink: ->
      @nextLink?.remove()
      return unless @options.displayShowMore and @unShownChildren() > 0
      stats = @getUnshownStats()
      @nextLink = $ '<div/>'
      showMore = true
      if not @options.threaded
        moreText = I18n.t('show_all_n_replies', {one: "Show one reply", other: "Show all %{count} replies"}, {count: stats.total})
      @nextLink.html entryStats({stats, moreText, showMore: yes})
      @nextLink.addClass 'showMore loadNext'
      if @options.threaded
        @nextLink.insertAfter @list
      else
        @nextLink.insertBefore @list

    getUnshownStats: ->
      start = @collection.length
      end = @collection.fullCollection.length
      unshown = @collection.fullCollection.toJSON().slice start, end
      total = 0
      unread = 0
      walk unshown, 'replies', (entry) ->
        total++
        unread++ if entry.read_state is 'unread'
      {total, unread}

    unShownChildren: ->
      @collection.fullCollection.length - @collection.length

    loadNextFromEvent: (event) ->
      event.stopPropagation()
      event.preventDefault()
      @loadNext()

    loadNext: ->
      if @options.threaded
        @collection.add @collection.fullCollection.getPage 'next'
      else
        @collection.reset @collection.fullCollection.toJSON()
      @renderNextLink()

    filter: @::afterRender

