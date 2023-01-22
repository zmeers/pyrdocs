#!/usr/bin/env bash

cd "$1"
# install or update pip and yq if they are not installed or up to date
for pkg in pydoc-markdown; do
  pip3 list --uptodate | grep "${pkg} " || pip3 install --upgrade ${pkg}
done

pydoc-markdown -m "$2"."$3" -I $(pwd) '{
    renderer: {
      type: markdown,
      descriptive_class_title: true,
      descriptive_module_title: true,
      add_module_prefix: true,
      add_member_class_prefix: true,
      insert_header_anchors: false,
      code_headers: true,
      signature_in_header: false,
      use_fixed_header_levels: true,
      header_level_by_type:{
        Module: 4,
        Class: 4,
        Function: 4,
        Method: 4,
        Data: 4
      }
    }
  }' > "$1"/docs/"$2"_"$3".md
