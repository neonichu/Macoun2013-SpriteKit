#!/bin/sh

# Search for todos in directory tree.
ag -G '.*\.m|.*\.h' 'TODO:|FIXME:'
