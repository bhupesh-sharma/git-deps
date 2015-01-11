$ = require("jquery")

# The list of nodes and links to feed into WebCola.
# These will be dynamically built as we retrieve them via XHR.
nodes = []
links = []

# WebCola requires links to refer to nodes by index within the
# nodes array, so as nodes are dynamically added, we need to
# be able to retrieve their index efficiently in order to add
# links to/from them.  This also allows us to avoid adding the
# same node twice.
node_index = {}

# Constraints will be added to try to keep siblings at the same y
# position.  For this we need to track siblings, which we do by
# mapping each parent to an array of its siblings in this hash.
# It also enables us to deduplicate links across multiple XHRs.
deps = {}

# Returns 1 iff a node was added, otherwise 0.
add_node = (commit) ->
    if commit.sha1 of node_index
        n = node commit.sha1
        n.explored ||= commit.explored
        return 0

    nodes.push commit
    node_index[commit.sha1] = nodes.length - 1
    return 1

# Returns 1 iff a dependency was added, otherwise 0.
add_dependency = (parent_sha1, child_sha1) ->
    deps[parent_sha1] = {}  unless parent_sha1 of deps

    # We've already got this link, presumably
    # from a previous XHR.
    return 0 if child_sha1 of deps[parent_sha1]
    deps[parent_sha1][child_sha1] = true
    add_link parent_sha1, child_sha1
    return 1

add_link = (parent_sha1, child_sha1) ->
    pi = node_index[parent_sha1]
    ci = node_index[child_sha1]
    link =
        source: pi
        target: ci
        value: 1 # no idea what WebCola needs this for

    links.push link
    return

# Returns true iff new data was added.
add_data = (data) ->
    new_nodes = 0
    new_deps = 0
    $.each data.commits, (i, commit) ->
        new_nodes += add_node(commit)

    $.each data.dependencies, (i, dep) ->
        new_deps += add_dependency(dep.parent, dep.child)

    if new_nodes > 0 or new_deps > 0
        return [
            new_nodes
            new_deps
            data.root
        ]

    return false

node = (sha1) ->
    i = node_index[sha1]
    unless i
        console.error "No index for SHA1 '#{sha1}'"
        return null
    return nodes[i]

module.exports =
    # Variables
    nodes: nodes
    links: links
    node_index: node_index
    deps: deps

    # Functions
    add: add_data
    node: node