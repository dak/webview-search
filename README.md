## Search Result Proposed Changes

### About

This document outlines conversions currently being done by Connexions/webview to search results from
Connexions/cnx-archive, and possible changes to reduce the number of conversions and their growth rate.

The following files are also included in this repository:
* `parse.coffee` contains the actual parsing method being used by webview
* `results.json` is an example set of results returned by `cnx-archive`
* `results-converted.json` is the same example set of results after it has been converted by webview

The results are from the following query: http://archive.cnx.org/search?q=title:physics%20pubYear:%222009%22

**THIS IS A DRAFT, AND THUS ALL PROPOSALS ARE TENTATIVE.**

### JSON Changes

#### query

##### limits

The only change being done by webview here is adding a human-friendly English name to each tag. Adding the names to
the JSON allows webview's templates to easily access the values without the need to write a template helper
to do a hash table conversion every time a view that uses them is rendered.

Since this change is language-specific UI element and not pure data (and we'll eventually support more than
just English), it really doesn't make sense for cnx-archive to include these converted names.

**PROPOSAL: NO CHANGE**

#### results

##### items

Only the authors are being converted here, although this is currently the largest and most expensive conversion.

Currently, cnx-archive only provides an array of uuids for the authors. Webview looks up the authors from
the array `results.auxiliary.authors` and replaces each uuid string with an author dictionary.

The code responsible is the following:
```coffeescript
  _.each response.results.items, (item) ->
    _.each item.authors, (author, index) ->
      item.authors[index] = authors.get(author).toJSON()
```

This involves stepping through every item and every author in each item, and then stepping through the array
of author objects to try to find a matching uuid. Some additional minimal expense is also added converting the
author array into a Backbone Collection for convenience.

I don't think it's entirely necessary (or desirable) for cnx-archive to perfectly match this converted format,
though. This format was actually previously used before converting to the current format, partly because
of the verbosity added (the converted authors are responsible for about 3Kb of file size difference in this
very small result set). Additionally, all of the authors still do need to be provided in a separate list for use by
filtering, otherwise we have the same problem, just in reverse.

It may be reasonable to write a Handlebars helper to have templates lookup authors when necessary, although this
change wouldn't have any impact on how many calculations were done to parse the data, it would just shift where
some of the parsing was being done (and actually be worse if item data was rendered more than once).

However, if the authors were provided as a dictionary, then a quick hash lookup when an author was needed would be
trivial.

The only problem with this is that a dictionary in JSON does not preserve order like an array, which we really want.

One potential solution would be to replace the author uuid strings with an integer representing the index of the
author in `results.auxiliary.authors`. Another option would be to provide a separate dictionary that provided a
quick hash lookup for the index using the author uuid, although this would increase the file size and force
an extra step needlessly.

**PROPOSAL: Replace author uuids with integers representing the index of the author in `results.auxiliary.authors`**

##### auxiliary

**NO CHANGES**

##### limits

Like `limits`, a human-friendly `name` is appended alongside each `tag`; however, it does not make sense for
cnx-archive to include this in the data it returns.

However, similar to `items`, authors are also included by uuid, forcing webview to loop through all of the authors
in `results.auxiliary.authors` a second time, just to figure out the author's full name:
```coffeescript
_.each limit.values, (value) ->
  author = authors.get(value.value).toJSON()
  value.displayValue = author.fullname
```

This additional loop could also be eliminated by providing the index for the author instead of the uuid.

**PROPOSAL: Replace author uuids with integers representing the index of the author in `results.auxiliary.authors`**
