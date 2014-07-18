# From: https://github.com/Connexions/webview/blob/c25033c15e544a6cd018c5e6e527238473ef657c/src/scripts/models/search-results.coffee#L67

parse: (response, options) ->
  response = super(arguments...)

  response.results.auxiliary or= {}

  authors = new Backbone.Collection(response.results.auxiliary.authors)
  types = new Backbone.Collection(response.results.auxiliary.types)

  # Add natural language translation alongside tags
  _.each response.query.limits, (limit) ->
    limit.name = FILTER_NAMES[limit.tag]

    if limit.tag is 'authorID'
      limit.name = 'Author ID'
      author = authors.get(limit.value).toJSON()
      limit.displayValue = "#{author.fullname} (#{author.id})"

  # Substitute author IDs in results with author objects
  _.each response.results.items, (item) ->
    _.each item.authors, (author, index) ->
      item.authors[index] = authors.get(author).toJSON()

  _.each response.results.limits, (limit) ->
    limit.name = FILTER_NAMES[limit.tag] # Add natural language translation alongside tags

    if limit.tag is 'authorID'
      _.each limit.values, (value) ->
        author = authors.get(value.value).toJSON()
        value.displayValue = author.fullname

    else if limit.tag is 'type'
      _.each limit.values, (value) ->
        type = types.get(value.value).toJSON()
        value.displayValue = type.name
        value.value = type.name

  return response
